#!/usr/bin/env python3
"""Check exclusion selection without changing Time Machine settings."""

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1] / "tm.sh"
SUDO = """#!/usr/bin/python3
import json, os, sys
with open(os.environ['TM_TEST_CALLS'], 'a') as stream:
    stream.write(json.dumps(sys.argv[1:]) + '\\n')
if sys.argv[1:] != ['-v'] and sys.argv[1:4] != ['/usr/bin/tmutil', 'addexclusion', '-p']:
    sys.exit(99)
"""


class TimeMachineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="time-machine-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.config = self.home / ".config/time-machine-exclusions"
        self.config.parent.mkdir(parents=True)
        self.repo = self.home / "Developer/sample"
        self.repo.mkdir(parents=True)
        self.calls = self.root / "calls.jsonl"
        sudo = self.root / "sudo"
        sudo.write_text(SUDO)
        sudo.chmod(0o755)
        self.script = self.root / "tm.sh"
        self.script.write_text(
            SOURCE.read_text()
            .replace("${HOME}", "${TM_TEST_HOME}")
            .replace("/usr/bin/sudo", '"$TM_TEST_SUDO"')
        )
        self.environment = {
            "PATH": "/usr/bin:/bin",
            "TM_TEST_HOME": str(self.home),
            "TM_TEST_SUDO": str(sudo),
            "TM_TEST_CALLS": str(self.calls),
            "APPLE_FIRMWARE_DIR": str(self.root / "firmware"),
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
        }

    def run_script(self):
        result = subprocess.run(
            ["/bin/bash", str(self.script)],
            env=self.environment,
            text=True,
            capture_output=True,
            timeout=15,
            check=False,
        )
        calls = (
            [json.loads(line) for line in self.calls.read_text().splitlines()]
            if self.calls.exists()
            else []
        )
        return result, calls

    def test_common_roots_and_only_ignored_build_outputs(self):
        subprocess.run(
            ["/usr/bin/git", "init", "-q", str(self.repo)],
            env=self.environment,
            check=True,
            timeout=10,
        )
        (self.repo / ".gitignore").write_text("target/\n")
        for name in ("target", "dist"):
            (self.repo / name).mkdir()
        result, calls = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        paths = [args[-1] for args in calls if args != ["-v"]]
        self.assertIn(str(self.root / "firmware"), paths)
        self.assertIn(str(self.repo / "target"), paths)
        self.assertNotIn(str(self.repo / "dist"), paths)
        self.assertFalse(any("/Developer/Mine/" in path for path in paths))

    def test_private_paths_are_literal_and_keep_spaces(self):
        marker = self.root / "must-not-exist"
        literal = f"{self.root}/literal $(touch {marker})"
        self.config.write_text(f"# local paths\n\n~/Data/with spaces\n{literal}")
        result, calls = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        paths = [args[-1] for args in calls if args != ["-v"]]
        self.assertIn(str(self.home / "Data/with spaces"), paths)
        self.assertIn(literal, paths)
        self.assertFalse(marker.exists())

    def test_relative_path_fails_before_sudo(self):
        self.config.write_text("relative/path\n")
        result, calls = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected an absolute or ~/ path", result.stderr)
        self.assertEqual(calls, [])


if __name__ == "__main__":
    unittest.main()
