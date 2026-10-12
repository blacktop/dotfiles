"""Check optional macOS setup failures without changing host settings."""

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
        env.update(
            TEST_CALLS=str(self.log),
            TEST_REPO_ROOT=str(SETUP.parent.parent),
            TEST_DENIED_DOMAIN="com.apple.Safari",
            TEST_DENIED_KEY="",
            TEST_DRIVER_STATUS="0",
        )
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
DRY_RUN=1
REPO_ROOT=$TEST_REPO_ROOT
quit_app() { :; }
safaridriver() { :; }
run() {
    printf '%s\\n' "$*" >> "$TEST_CALLS"
    if [[ "$1" == /usr/bin/defaults &&
          ( "${3:-}" == "$TEST_DENIED_DOMAIN" || "$TEST_DENIED_DOMAIN" == '*' ) &&
          ( "${4:-}" == "$TEST_DENIED_KEY" || "$TEST_DENIED_KEY" == '*' ) ]]; then
        return 77
    fi
    if [[ "$1" == safaridriver ]]; then
        return "$TEST_DRIVER_STATUS"
    fi
}
later_section() { run later-command; }
run_section Safari 'Safari settings' configure_safari
run_section TextEdit 'TextEdit settings' configure_textedit
run_section Terminal 'Terminal settings' configure_terminal
run_section Later 'Later settings' later_section
printf 'counts:%d:%d:%d\\n' "$APPLIED_COUNT" "$SKIPPED_COUNT" "$INCOMPLETE_COUNT"
""",
            **overrides,
        )

    def assert_continued(self, result, incomplete="Safari"):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("counts:3:0:1", result.stdout)
        self.assertIn(f"{incomplete} incomplete", result.stderr)
        for section in ("Safari", "TextEdit", "Terminal", "Later"):
            if section != incomplete:
                self.assertIn(f"{section} complete", result.stdout)

    def run_preflight(
        self,
        *,
        requested_mode="",
        choice="Continue setup",
        dry_run=False,
        has_ui=True,
        gum_status=0,
        open_status=0,
    ):
        return self.run_script(
            """
MODE=all
DRY_RUN=$TEST_DRY_RUN
GUM=test_gum
has_gum_ui() { [[ "$TEST_HAS_UI" == 1 ]]; }
test_gum() {
    printf 'gum %s\\n' "$*" >> "$TEST_CALLS"
    printf '%s\\n' "$TEST_CHOICE"
    return "$TEST_GUM_STATUS"
}
run() {
    printf '%s\\n' "$*" >> "$TEST_CALLS"
    return "$TEST_OPEN_STATUS"
}
preflight_full_disk_access "$TEST_REQUESTED_MODE"
printf 'continued\\n'
""",
            TEST_REQUESTED_MODE=requested_mode,
            TEST_CHOICE=choice,
            TEST_DRY_RUN=str(int(dry_run)),
            TEST_HAS_UI=str(int(has_ui)),
            TEST_GUM_STATUS=str(gum_status),
            TEST_OPEN_STATUS=str(open_status),
        )

    def test_permission_prompt_opens_settings_and_stops(self):
        result = self.run_preflight(choice="Open Full Disk Access settings and stop")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(
            "/usr/bin/open x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
            self.calls,
        )
        self.assertIn("reopening the terminal app", result.stdout)
        self.assertNotIn("continued", result.stdout)

    def test_permission_prompt_can_continue(self):
        result = self.run_preflight(requested_mode="review")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("continued", result.stdout)
        self.assertEqual(len(self.calls), 1)
        self.assertTrue(self.calls[0].startswith("gum choose "))

    def test_permission_prompt_is_skipped_when_noninteractive(self):
        for options in (
            {"requested_mode": "all"},
            {"dry_run": True},
            {"has_ui": False},
        ):
            with self.subTest(options=options):
                self.log.write_text("")
                result = self.run_preflight(**options)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("continued", result.stdout)
                self.assertEqual(self.calls, [])

    def test_permission_prompt_cancel_and_interrupt_stop_setup(self):
        for options, status in (
            ({"choice": "Cancel"}, 0),
            ({"gum_status": 130}, 130),
        ):
            with self.subTest(options=options):
                self.log.write_text("")
                result = self.run_preflight(**options)
                self.assertEqual(result.returncode, status, result.stderr)
                self.assertNotIn("continued", result.stdout)
                self.assertFalse(any("/usr/bin/open" in call for call in self.calls))

    def test_permission_settings_open_failure_explains_manual_route(self):
        result = self.run_preflight(
            choice="Open Full Disk Access settings and stop", open_status=1
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Full Disk Access manually", result.stderr)
        self.assertNotIn("continued", result.stdout)

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

    def test_textedit_denial_continues_setup(self):
        result = self.run_sections(
            TEST_DENIED_DOMAIN="com.apple.TextEdit", TEST_DENIED_KEY="RichText"
        )
        self.assert_continued(result, "TextEdit")
        self.assertIn("Could not write TextEdit preference 'RichText'", result.stderr)
        self.assertFalse(any("PlainTextEncoding" in call for call in self.calls))

    def test_later_textedit_denial_stops_textedit_only(self):
        result = self.run_sections(
            TEST_DENIED_DOMAIN="com.apple.TextEdit",
            TEST_DENIED_KEY="PlainTextEncodingForWrite",
        )
        self.assert_continued(result, "TextEdit")
        self.assertFalse(any("TabWidth" in call for call in self.calls))

    def test_terminal_denial_skips_theme_and_continues(self):
        result = self.run_sections(
            TEST_DENIED_DOMAIN="com.apple.Terminal", TEST_DENIED_KEY="StringEncodings"
        )
        self.assert_continued(result, "Terminal")
        self.assertFalse(any("SecureKeyboardEntry" in call for call in self.calls))
        self.assertFalse(any(call.startswith("/usr/bin/open ") for call in self.calls))

    def test_later_terminal_denial_stops_terminal_only(self):
        result = self.run_sections(
            TEST_DENIED_DOMAIN="com.apple.Terminal",
            TEST_DENIED_KEY="Default Window Settings",
        )
        self.assert_continued(result, "Terminal")
        self.assertTrue(any(call.startswith("/usr/bin/open ") for call in self.calls))
        self.assertFalse(any("Startup Window Settings" in call for call in self.calls))

    def test_multiple_protected_domains_can_fail(self):
        result = self.run_sections(TEST_DENIED_DOMAIN="*", TEST_DENIED_KEY="*")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("counts:1:0:3", result.stdout)
        for section in ("Safari", "TextEdit", "Terminal"):
            self.assertIn(f"{section} incomplete", result.stderr)
        self.assertIn("Later complete", result.stdout)

    def test_success_counts_all_sections(self):
        result = self.run_sections()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("counts:4:0:0", result.stdout)
        self.assertIn("Safari complete", result.stdout)
        self.assertNotIn("incomplete", result.stderr)

    def run_time_machine(self, status):
        tm_script = self.root / "tm.sh"
        tm_script.write_text(
            """#!/bin/bash
set -e
printf '%s\\n' 'first exclusion' >> "$TEST_CALLS"
if [[ "$TEST_TM_STATUS" != 0 ]]; then
    printf '%s\\n' 'tmutil: addexclusion requires Full Disk Access privileges.' >&2
fi
/bin/bash -c 'exit "$TEST_TM_STATUS"'
printf '%s\\n' 'second exclusion' >> "$TEST_CALLS"
"""
        )
        tm_script.chmod(0o755)
        return self.run_script(
            """
MODE=all
later_section() { :; }
run_section 'Time Machine' 'Time Machine exclusions' configure_time_machine
run_section Later 'Later settings' later_section
printf 'counts:%d:%d:%d\\n' "$APPLIED_COUNT" "$SKIPPED_COUNT" "$INCOMPLETE_COUNT"
""",
            TEST_TM_STATUS=str(status),
        )

    def test_time_machine_denial_continues_setup(self):
        result = self.run_time_machine(77)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("requires Full Disk Access", result.stderr)
        self.assertIn("exclusions stopped (exit 77)", result.stderr)
        self.assertIn("bash macos/tm.sh", result.stderr)
        self.assertIn("Time Machine incomplete", result.stderr)
        self.assertIn("Later complete", result.stdout)
        self.assertIn("counts:1:0:1", result.stdout)
        self.assertEqual(self.calls, ["first exclusion"])

    def test_time_machine_success_is_counted(self):
        result = self.run_time_machine(0)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Time Machine complete", result.stdout)
        self.assertIn("counts:2:0:0", result.stdout)
        self.assertNotIn("incomplete", result.stderr)
        self.assertEqual(self.calls, ["first exclusion", "second exclusion"])

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
