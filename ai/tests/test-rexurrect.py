#!/usr/bin/env python3
"""Exercise account routing through the portable rexurrect launcher."""

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FISH = shutil.which("fish")
LAUNCHER = shutil.which("rexurrect-launch")
UUID = "01234567-89ab-4cde-8fab-0123456789ab"

STUB = r"""#!/usr/bin/python3
import json, os, sys
from pathlib import Path
name, args = Path(sys.argv[0]).name, sys.argv[1:]
if name == "security":
    sys.exit(44)
if name == "jq":
    assert args[-1] in (str(Path.home() / ".claude/settings.json"),
                       str(Path.home() / ".claude-ddb/settings.json"))
    print(os.environ[{'.model // ""': "RR_TEST_MODEL", '.effortLevel // ""': "RR_TEST_EFFORT"}[args[1]]])
    sys.exit(0)
entry = {"program": name, "args": args}
if name in ("claude", "codex"):
    entry["route"] = os.environ.get("CLAUDE_CONFIG_DIR" if name == "claude" else "CODEX_HOME", "")
    entry["harness"] = os.environ.get("RR_HARNESS", "")
    entry["host"] = os.environ.get("RR_HOST", "")
    entry["model"] = os.environ.get("RR_MODEL", "")
    entry["effort"] = os.environ.get("RR_EFFORT", "")
with open(os.environ["RR_TEST_LOG"], "a") as stream:
    stream.write(json.dumps(entry) + "\n")
sys.exit(int(os.environ.get("RR_TEST_CLEAR_STATUS" if name == "rexurrect" else "RR_TEST_AGENT_STATUS", "0")))
"""

DRIVER = """function _claude_patch_ctf
end
for name in codex codex-team codex-api claude claude-ddb claude-team
    source "$RR_TEST_ROOT/fish/functions/$name.fish"
end
set -l rr_command $argv[1]
set -e argv[1]
$rr_command $argv
exit $status
"""


class RexReceiptTests(unittest.TestCase):
    def setUp(self):
        if not FISH or not LAUNCHER:
            self.skipTest("fish and rexurrect-launch must be installed")
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.scratch = Path(self.temp.name)
        self.bin = self.scratch / "bin"
        self.bin.mkdir()
        (self.bin / "rexurrect-launch").symlink_to(LAUNCHER)
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
            "RR_TEST_LOG": str(self.log),
            "RR_TEST_MODEL": "claude-fable-5-1[1m]",
            "RR_TEST_EFFORT": "xhigh",
            "REX_SESSION": "session:" + UUID,
            "REX_BLOCK": "block:" + UUID,
            "REXURRECT_SERVER": "unix:///private/tmp/rex-receipt-test.sock",
            "REXURRECT_STATE_DIR": str(self.scratch / "state"),
        }

    def launch(self, *args, changes=None):
        self.log.write_text("")
        result = subprocess.run(
            [FISH, "--no-config", str(self.driver), *args],
            env=self.environment | (changes or {}),
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )
        return result, [json.loads(line) for line in self.log.read_text().splitlines()]

    def cleared(self, harness):
        return {
            "program": "rexurrect",
            "args": [
                "receipt",
                "clear",
                "--server",
                self.environment["REXURRECT_SERVER"],
                "--state-dir",
                self.environment["REXURRECT_STATE_DIR"],
                "--session",
                "session:" + UUID,
                "--block",
                "block:" + UUID,
                "--command",
                harness,
            ],
        }

    def test_claude_routing_and_explicit_overrides(self):
        for harness, args, route, model, effort in (
            ("claude", [], "", "claude-fable-5-1[1m]", "xhigh"),
            (
                "claude-ddb",
                ["--model", "claude-opus-4-8", "--effort", "high"],
                str(Path.home() / ".claude-ddb"),
                "claude-opus-4-8",
                "high",
            ),
        ):
            with self.subTest(harness=harness):
                result, calls = self.launch(harness, *args)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    calls,
                    [
                        {
                            "program": "claude",
                            "host": "claude",
                            "args": args,
                            "route": route,
                            "harness": harness,
                            "model": model,
                            "effort": effort,
                        },
                        self.cleared(harness),
                    ],
                )

    def test_codex_fresh_and_resume_preserve_account_and_status(self):
        for harness, route in (
            ("codex", ""),
            ("codex-team", str(Path.home() / ".codex-team")),
        ):
            for args, model in (
                ([], ""),
                (["resume", UUID, "-m", "astra-cyber-preview", "two words"], "astra-cyber-preview"),
            ):
                with self.subTest(harness=harness, args=args):
                    result, calls = self.launch(
                        harness, *args, changes={"RR_TEST_AGENT_STATUS": "7"}
                    )
                    self.assertEqual(result.returncode, 7, result.stderr)
                    self.assertEqual(
                        calls,
                        [
                            {
                                "program": "codex",
                                "host": "codex",
                                "args": ["--no-daemon", *args],
                                "route": route,
                                "harness": harness,
                                "model": model,
                                "effort": "",
                            },
                            self.cleared(harness),
                        ],
                    )

    def test_nested_and_conflicting_launches_do_not_claim_receipts(self):
        for harness in ("claude", "claude-ddb", "codex", "codex-team"):
            for changes in (
                {"CLAUDECODE": "1"},
                {"CODEX_THREAD_ID": UUID},
                {"RR_HOST": ""},
                {"RR_HARNESS": ""},
                {"RR_HOST": "claude"},
                {"RR_HARNESS": "another-account"},
            ):
                with self.subTest(harness=harness, changes=changes):
                    result, calls = self.launch(harness, "two words", changes=changes)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(len(calls), 1)
                    self.assertEqual(calls[0]["args"], ["two words"])
                    self.assertEqual(calls[0]["harness"], "")
                    self.assertEqual(calls[0]["host"], "")

    def test_manual_accounts_keep_their_route(self):
        for harness, changes, route in (
            ("claude-team", {}, str(Path.home() / ".claude-team")),
            ("codex-api", {}, str(Path.home() / ".codex-api")),
            (
                "claude",
                {"CLAUDE_CONFIG_DIR": "/private/tmp/custom-claude"},
                "/private/tmp/custom-claude",
            ),
            (
                "codex",
                {"CODEX_HOME": "/private/tmp/custom-codex"},
                "/private/tmp/custom-codex",
            ),
        ):
            with self.subTest(harness=harness):
                result, calls = self.launch(
                    harness, "--help", changes=changes | {"RR_HOST": "codex", "RR_HARNESS": "codex-team"}
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(len(calls), 1)
                self.assertEqual(calls[0]["route"], route)
                self.assertEqual(calls[0]["harness"], "")

    def test_cleanup_failure_and_missing_binary(self):
        for harness in ("claude", "codex-team"):
            with self.subTest(harness=harness):
                result, calls = self.launch(
                    harness,
                    changes={"RR_TEST_AGENT_STATUS": "7", "RR_TEST_CLEAR_STATUS": "8"},
                )
                self.assertEqual(result.returncode, 8, result.stderr)
                self.assertEqual(calls[-1], self.cleared(harness))
        (self.bin / "rexurrect").unlink()
        result, calls = self.launch("codex-team")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call["program"] for call in calls], ["codex"])


if __name__ == "__main__":
    unittest.main()
