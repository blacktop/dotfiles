"""Check Rosetta setup decisions without installing host software."""

import os
import subprocess
import unittest
from pathlib import Path

SETUP = Path(__file__).resolve().parents[1] / "setup.sh"


class RosettaTests(unittest.TestCase):
    def test_install_decisions(self):
        source = SETUP.read_text()
        start = source.index("function has_gum_prompt_ui() {")
        end = source.index("function initialize_xcode() {")
        script = (
            "set -e\n"
            + source[start:end]
            + """
info() { :; }
running() { :; }
uname() { printf '%s\\n' "$TEST_ARCH"; }
sysctl() { printf '%s\\n' "$TEST_ARM64"; }
test() { [[ "$TEST_INSTALLED" == 1 ]]; }
has_gum_prompt_ui() { [[ "$TEST_HAS_UI" == 1 ]]; }
gum() {
    printf '%s\\n' prompt
    return "$TEST_CHOICE_STATUS"
}
sudo() {
    printf '%s\\n' "$*"
    return "$TEST_INSTALL_STATUS"
}
initialize_rosetta
printf '%s\\n' finished
"""
        )
        installer = "/usr/sbin/softwareupdate --install-rosetta --agree-to-license"
        cases = (
            ("Intel", {"TEST_ARCH": "x86_64", "TEST_ARM64": "0"}, [], 0),
            (
                "translated shell",
                {"TEST_ARCH": "x86_64", "TEST_INSTALLED": "1"},
                [],
                0,
            ),
            ("accepted", {}, ["prompt", installer], 0),
            ("declined", {"TEST_CHOICE_STATUS": "1"}, ["prompt"], 0),
            ("interrupted", {"TEST_CHOICE_STATUS": "130"}, ["prompt"], 130),
            ("unattended", {"TEST_HAS_UI": "0"}, [], 0),
            (
                "explicit yes",
                {"TEST_HAS_UI": "0", "SETUP_ROSETTA": "yes"},
                [installer],
                0,
            ),
            ("explicit no", {"SETUP_ROSETTA": "no"}, [], 0),
            (
                "installed with explicit yes",
                {"TEST_INSTALLED": "1", "SETUP_ROSETTA": "yes"},
                [],
                0,
            ),
            (
                "installer failure",
                {"TEST_INSTALL_STATUS": "7"},
                ["prompt", installer],
                7,
            ),
        )
        for name, overrides, expected_calls, expected_status in cases:
            with self.subTest(name=name):
                env = os.environ.copy()
                env.update(
                    TEST_ARCH="arm64",
                    TEST_ARM64="1",
                    TEST_INSTALLED="0",
                    TEST_HAS_UI="1",
                    TEST_CHOICE_STATUS="0",
                    TEST_INSTALL_STATUS="0",
                    SETUP_ROSETTA="",
                )
                env.update(overrides)
                result = subprocess.run(
                    ["/bin/bash", "-s"],
                    input=script,
                    env=env,
                    capture_output=True,
                    text=True,
                    check=False,
                    timeout=10,
                )
                self.assertEqual(result.returncode, expected_status, result.stderr)
                expected_output = expected_calls + (
                    ["finished"] if expected_status == 0 else []
                )
                self.assertEqual(result.stdout.splitlines(), expected_output)


if __name__ == "__main__":
    unittest.main()
