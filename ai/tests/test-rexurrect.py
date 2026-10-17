#!/usr/bin/env python3
"""Exercise Rex receipt hooks through the actual Fish account functions."""

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FISH = shutil.which("fish")
JQ = shutil.which("jq")
UUID = "01234567-89ab-4cde-8fab-0123456789ab"

STUB = r"""#!/usr/bin/python3
import json, os, subprocess, sys
from pathlib import Path
name, args = Path(sys.argv[0]).name, sys.argv[1:]
if name == "security":
    sys.exit(44)
if name == "jq":
    if args[-1] in (str(Path.home() / ".claude/settings.json"),
                    str(Path.home() / ".claude-ddb/settings.json")):
        print(os.environ["RR_TEST_MODEL" if args[1].startswith(".model") else "RR_TEST_EFFORT"])
        sys.exit(0)
    os.execv(os.environ["RR_TEST_JQ"], ["jq"] + args)
if name == "rexurrect" and args == ["receipt", "set", "--help"]:
    sys.exit(1 if os.environ.get("RR_TEST_OLD") else 0)
entry = {"program": name, "args": args}
if name in ("claude", "codex"):
    entry["route"] = os.environ.get("CLAUDE_CONFIG_DIR" if name == "claude" else "CODEX_HOME", "")
    entry["harness"] = os.environ.get("RR_HARNESS", "")
with open(os.environ["RR_TEST_LOG"], "a") as stream:
    stream.write(json.dumps(entry) + "\n")
if name == "claude":
    for event in ("SessionStart", "SessionEnd"):
        payload = {"hook_event_name": event, "session_id": os.environ["RR_TEST_UUID"],
                   "model": os.environ.get("RR_TEST_EVENT_MODEL", "")}
        result = subprocess.run(["/bin/sh", os.environ["RR_TEST_HOOK"]],
            input=json.dumps(payload), text=True, timeout=10)
        if result.returncode:
            sys.exit(result.returncode)
if name == "rexurrect":
    sys.exit(int(os.environ.get("RR_TEST_" + args[1].upper() + "_STATUS", "0")))
sys.exit(int(os.environ.get("RR_TEST_AGENT_STATUS", "0")))
"""

DRIVER = """function _claude_patch_ctf
end
for name in _rexurrect_codex codex codex-team claude claude-ddb
    source "$RR_TEST_ROOT/fish/functions/$name.fish"
end
set -l rr_command $argv[1]
set -e argv[1]
$rr_command $argv
exit $status
"""


class RexReceiptTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.scratch = Path(self.temp.name)
        self.bin = self.scratch / "bin"
        self.bin.mkdir()
        for name in ("security", "jq", "rexurrect", "claude", "codex"):
            binary = self.bin / name
            binary.write_text(STUB)
            binary.chmod(0o755)
        self.driver = self.scratch / "driver.fish"
        self.driver.write_text(DRIVER)
        self.log = self.scratch / "calls.jsonl"
        self.environment = {
            "HOME": str(Path.home()),
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "RR_TEST_ROOT": str(ROOT),
            "RR_TEST_JQ": JQ,
            "RR_TEST_LOG": str(self.log),
            "RR_TEST_HOOK": str(ROOT / "ai/hooks/rexurrect-claude.sh"),
            "RR_TEST_UUID": UUID,
            "RR_TEST_MODEL": "claude-fable-5-1[1m]",
            "RR_TEST_EFFORT": "xhigh",
            "REX_SESSION": "session:" + UUID,
            "REX_BLOCK": "block:" + UUID,
            "REXURRECT_SERVER": "unix:///private/tmp/rex-receipt-test.sock",
            "REXURRECT_STATE_DIR": str(self.scratch / "state"),
        }

    def run_command(self, command, *, changes=None, payload=None):
        self.log.write_text("")
        result = subprocess.run(
            command,
            env=self.environment | (changes or {}),
            input=payload,
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )
        return result, [json.loads(line) for line in self.log.read_text().splitlines()]

    def launch(self, *args, **kwargs):
        return self.run_command(
            [FISH, "--no-config", str(self.driver), *args], **kwargs
        )

    def receipt(self, operation, harness=None, model="", effort=""):
        args = [
            "receipt",
            operation,
            "--server",
            self.environment["REXURRECT_SERVER"],
            "--state-dir",
            self.environment["REXURRECT_STATE_DIR"],
            "--session",
            "session:" + UUID,
            "--block",
            "block:" + UUID,
        ]
        if operation == "set":
            args += ["--harness", harness]
        args += ["--conversation", UUID]
        if operation == "set":
            args += ["--model", model, "--effort", effort]
        return {"program": "rexurrect", "args": args}

    def test_claude_routing_defaults_and_overrides(self):
        cases = [
            ("claude", [], {}, "", "claude-fable-5-1", "xhigh"),
            (
                "claude-ddb",
                ["--model", "claude-opus-4-8", "--effort", "high"],
                {},
                str(Path.home() / ".claude-ddb"),
                "claude-opus-4-8",
                "high",
            ),
            (
                "claude",
                ["--model", "claude-opus-4-8"],
                {"RR_TEST_EVENT_MODEL": "claude-fable-5-1"},
                "",
                "claude-fable-5-1",
                "xhigh",
            ),
        ]
        for harness, args, changes, route, model, effort in cases:
            with self.subTest(harness=harness, args=args):
                result, calls = self.launch(harness, *args, changes=changes)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    calls,
                    [
                        {
                            "program": "claude",
                            "args": args,
                            "route": route,
                            "harness": harness,
                        },
                        self.receipt("set", harness, model, effort),
                        self.receipt("clear"),
                    ],
                )

    def test_codex_resume_preserves_argv_route_and_status(self):
        for harness, route in (
            ("codex", ""),
            ("codex-team", str(Path.home() / ".codex-team")),
        ):
            with self.subTest(harness=harness):
                args = [
                    "resume",
                    UUID,
                    "-m",
                    "astra-cyber-preview",
                    "-c",
                    'model_reasoning_effort="xhigh"',
                    "two words",
                ]
                result, calls = self.launch(
                    harness, *args, changes={"RR_TEST_AGENT_STATUS": "7"}
                )
                self.assertEqual(result.returncode, 7, result.stderr)
                self.assertEqual(
                    calls,
                    [
                        self.receipt("set", harness, "astra-cyber-preview", "xhigh"),
                        {
                            "program": "codex",
                            "args": args,
                            "route": route,
                            "harness": "",
                        },
                        self.receipt("clear"),
                    ],
                )

    def test_codex_receipt_failures(self):
        for changes, programs, expected in (
            ({"RR_TEST_SET_STATUS": "9"}, ["rexurrect"], 9),
            (
                {"RR_TEST_CLEAR_STATUS": "8", "RR_TEST_AGENT_STATUS": "7"},
                ["rexurrect", "codex", "rexurrect"],
                8,
            ),
        ):
            with self.subTest(changes=changes):
                result, calls = self.launch(
                    "codex-team", "resume", UUID, changes=changes
                )
                self.assertEqual(result.returncode, expected, result.stderr)
                self.assertEqual([call["program"] for call in calls], programs)

    def test_ineligible_launches_and_old_binary_are_inert(self):
        cases = [
            ("claude", [], {"CLAUDE_CONFIG_DIR": str(Path.home() / ".claude-team")}),
            ("claude", [], {"CLAUDE_CONFIG_DIR": "/private/tmp/custom-claude"}),
            ("claude", [], {"RR_TEST_OLD": "1"}),
            ("claude", [], {"REX_BLOCK": ""}),
            ("codex", ["resume", "--last"], {}),
            (
                "codex",
                ["resume", UUID],
                {"CODEX_HOME": str(Path.home() / ".codex-api")},
            ),
            ("codex-team", ["resume", UUID], {"RR_TEST_OLD": "1"}),
            ("codex-team", ["resume", UUID], {"REX_SESSION": ""}),
        ]
        for harness, args, changes in cases:
            with self.subTest(harness=harness, changes=changes):
                result, calls = self.launch(harness, *args, changes=changes)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(len(calls), 1)
                self.assertEqual(calls[0]["args"], args)
        (self.bin / "rexurrect").unlink()
        result, calls = self.launch("codex-team", "resume", UUID)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call["program"] for call in calls], ["codex"])

    def test_hook_rejects_bad_input_without_registering(self):
        for payload in (
            "{",
            "{}",
            '{"hook_event_name":"SessionStart","session_id":null}',
            "\n" * 65537,
        ):
            with self.subTest(size=len(payload)):
                result, calls = self.run_command(
                    ["/bin/sh", self.environment["RR_TEST_HOOK"]],
                    changes={"RR_HARNESS": "claude"},
                    payload=payload,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(calls, [])


if __name__ == "__main__":
    unittest.main()
