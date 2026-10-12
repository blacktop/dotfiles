"""Check Safari failure handling without changing macOS preferences."""

import os
import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path

SETUP = Path(__file__).resolve().parents[1] / "setup.sh"


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="test-macos-setup-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.log = self.root / "calls"
        self.log.touch()
        definitions, separator, _ = SETUP.read_text().partition("\nwhile (($#)); do\n")
        self.assertTrue(separator, "could not isolate the setup function definitions")
        self.functions = self.root / "functions.sh"
        self.functions.write_text(definitions + "\n")

    def run_script(self, body, **overrides):
        env = os.environ.copy()
        env.update(TEST_CALLS=str(self.log), TEST_DENIED_KEY="", TEST_DRIVER_STATUS="0")
        env.update(overrides)
        script = f"source {shlex.quote(str(self.functions))}\n" + body
        result = subprocess.run(
            ["/bin/bash", "-c", script],
            env=env,
            check=False,
            capture_output=True,
            text=True,
            timeout=15,
        )
        self.calls = self.log.read_text().splitlines()
        return result

    def run_sections(self, **overrides):
        return self.run_script(
            """
MODE=all
quit_app() { :; }
safaridriver() { :; }
run() {
    printf '%s\\n' "$*" >> "$TEST_CALLS"
    if [[ "$1" == /usr/bin/defaults && "${3:-}" == com.apple.Safari && "${4:-}" == "$TEST_DENIED_KEY" ]]; then
        return 77
    fi
    if [[ "$1" == safaridriver ]]; then
        return "$TEST_DRIVER_STATUS"
    fi
}
run_section Safari 'Safari settings' configure_safari
run_section TextEdit 'TextEdit settings' configure_textedit
printf 'counts:%d:%d:%d\\n' "$APPLIED_COUNT" "$SKIPPED_COUNT" "$INCOMPLETE_COUNT"
""",
            **overrides,
        )

    def assert_continued(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("counts:1:0:1", result.stdout)
        self.assertIn("Safari incomplete", result.stderr)
        self.assertIn("TextEdit complete", result.stdout)

    def test_protected_domain_denial_continues_setup(self):
        result = self.run_sections(TEST_DENIED_KEY="IncludeDevelopMenu")
        self.assert_continued(result)
        self.assertIn("Full Disk Access", result.stderr)
        self.assertNotIn("safaridriver --enable", self.calls)
        self.assertFalse(any("UniversalSearchEnabled" in call for call in self.calls))

    def test_later_preference_denial_stops_safari_only(self):
        result = self.run_sections(TEST_DENIED_KEY="AutoFillPasswords")
        self.assert_continued(result)
        self.assertIn("safaridriver --enable", self.calls)
        self.assertFalse(any("AutoFillCreditCardData" in call for call in self.calls))

    def test_webdriver_failure_still_applies_preferences(self):
        result = self.run_sections(TEST_DRIVER_STATUS="1")
        self.assert_continued(result)
        self.assertTrue(
            any("WarnAboutFraudulentWebsites" in call for call in self.calls)
        )

    def test_success_counts_both_sections(self):
        result = self.run_sections()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("counts:2:0:0", result.stdout)
        self.assertIn("Safari complete", result.stdout)
        self.assertNotIn("incomplete", result.stderr)

    def test_failed_defaults_write_keeps_failure_status(self):
        result = self.run_script(
            """
run() { return 77; }
if defaults_write NSGlobalDomain Test -bool true; then
    exit 99
else
    status=$?
fi
printf 'status:%d changed:%d\\n' "$status" "$PREFERENCES_CHANGED"
"""
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("status:77 changed:0", result.stdout)

    def test_unhandled_failure_still_stops_setup(self):
        result = self.run_script(
            """
run() { return 77; }
defaults_write NSGlobalDomain Test -bool true
printf 'unexpected continuation\\n'
"""
        )
        self.assertEqual(result.returncode, 77, result.stderr)
        self.assertNotIn("unexpected continuation", result.stdout)


if __name__ == "__main__":
    unittest.main()
