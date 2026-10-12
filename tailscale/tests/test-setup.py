#!/usr/bin/env python3
"""Exercise installer decisions without changing the host or its VPN."""

import json
import os
import shlex
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SETUP = Path(__file__).resolve().parents[1] / "setup.sh"


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="test-tailscale-setup-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "calls.jsonl"
        self.log.touch()
        dispatcher = self.bin / "dispatcher"
        dispatcher.write_text(
            f"#!{sys.executable}\n"
            + """import json, os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["TEST_CALLS"], "a") as log:
    log.write(json.dumps([name] + args) + "\\n")
if name == "uname":
    print("Darwin")
elif name == "brew":
    if args == ["list", "--formula", "-1"]:
        if os.environ.get("TEST_FORMULA_STATUS", "1") == "0":
            print("tailscale")
        sys.exit(int(os.environ.get("TEST_FORMULA_LIST_STATUS", "0")))
    if args == ["list", "--cask", "-1"]:
        if os.environ.get("TEST_CASK_STATUS", "1") == "0":
            print("tailscale-app")
    if args == ["--prefix", "tailscale"]:
        print(os.environ["TEST_PREFIX"])
    if args[:1] == ["install"]:
        sys.exit(int(os.environ.get("TEST_INSTALL_STATUS", "0")))
elif name == "gum":
    print(os.environ.get("TEST_CHOICE", "skip"))
    sys.exit(int(os.environ.get("TEST_GUM_STATUS", "0")))
elif name == "sudo":
    os.execv(args[0], args)
elif name == "tailscale" and args[:1] == ["status"]:
    sys.exit(int(os.environ.get("TEST_CONNECTION_STATUS", "1")))
elif name == "tailscale" and args[:1] == ["up"]:
    if os.environ.get("TEST_SAVED_PREFS") == "1" and len(args) > 1:
        print("Refusing to reset previously configured settings", file=sys.stderr)
        sys.exit(9)
"""
        )
        dispatcher.chmod(0o755)
        for name in ("uname", "brew", "gum", "sudo", "open", "tailscale"):
            (self.bin / name).symlink_to(dispatcher)

    def run_setup(self, *args, terminal=False, gui="", manual=False, **overrides):
        # OS/app detection is isolated here; installation, service, and login
        # commands still run through the real script and recorded executables.
        self.log.write_text("")
        env = os.environ.copy()
        env.update(
            PATH=f"{self.bin}:/usr/bin:/bin:/usr/sbin:/sbin",
            TEST_CALLS=str(self.log),
            TEST_PREFIX=str(self.root),
            SETUP_TAILSCALE_PROFILE="",
        )
        env.update(overrides)
        gui_result = f"printf '%s\\n' {shlex.quote(gui)}" if gui else "return 1"
        script = (
            f"source {shlex.quote(str(SETUP))}\n"
            f"has_terminal() {{ return {0 if terminal else 1}; }}\n"
            f"installed_gui_kind() {{ {gui_result}; }}\n"
            f"has_manual_daemon() {{ return {0 if manual else 1}; }}\n"
            'main "$@"\n'
        )
        result = subprocess.run(
            ["/bin/bash", "-c", script, "test-setup", *args],
            env=env,
            check=False,
            capture_output=True,
            text=True,
            timeout=15,
        )
        self.calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        return result

    def assert_ok(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)

    def assert_no_mutations(self):
        for call in self.calls:
            self.assertNotIn(call[0], ("sudo", "open", "tailscale"), call)
            if call[0] == "brew":
                self.assertNotIn(call[1], ("install", "services"), call)

    def test_unattended_default_skips(self):
        self.assert_ok(self.run_setup())
        self.assertEqual(self.calls, [])

    def test_existing_installations_skip_profile_prompt(self):
        cases = (
            ("formula", {"TEST_FORMULA_STATUS": "0"}),
            ("cask", {"TEST_CASK_STATUS": "0"}),
            ("standalone app", {"gui": "standalone"}),
            ("other app", {"gui": "app-store-or-unknown"}),
            ("manual daemon", {"manual": True}),
        )
        for name, options in cases:
            with self.subTest(name=name):
                result = self.run_setup(terminal=True, **options)
                self.assert_ok(result)
                self.assertIn("already installed", result.stderr)
                self.assertFalse(any(call[0] == "gum" for call in self.calls))
                self.assert_no_mutations()

    def test_daemon_on_path_skips_profile_prompt(self):
        (self.bin / "tailscaled").symlink_to(self.bin / "dispatcher")
        self.assert_ok(self.run_setup(terminal=True))
        self.assertFalse(any(call[0] == "gum" for call in self.calls))
        self.assert_no_mutations()

    def test_invalid_profile_fails_before_changes(self):
        result = self.run_setup("--profile", "typo")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Unknown profile", result.stderr)
        self.assertEqual(self.calls, [])

    def test_server_starts_root_service_without_login(self):
        self.assert_ok(self.run_setup(SETUP_TAILSCALE_PROFILE="server"))
        self.assertIn(["brew", "install", "--formula", "tailscale"], self.calls)
        self.assertIn(
            ["sudo", str(self.bin / "brew"), "services", "start", "tailscale"],
            self.calls,
        )
        self.assertFalse(any(call[0] == "tailscale" for call in self.calls))

    def test_stopped_server_preserves_saved_preferences(self):
        self.assert_ok(
            self.run_setup(
                "--profile",
                "server",
                terminal=True,
                TEST_FORMULA_STATUS="0",
                TEST_SAVED_PREFS="1",
            )
        )
        self.assertIn(["tailscale", "up"], self.calls)
        self.assertFalse(
            any("--reset" in call or "--ssh" in call for call in self.calls)
        )

    def test_connected_server_preserves_preferences(self):
        self.assert_ok(
            self.run_setup(
                "--profile",
                "server",
                terminal=True,
                TEST_FORMULA_STATUS="0",
                TEST_INSTALL_STATUS="7",
                TEST_CONNECTION_STATUS="0",
            )
        )
        self.assertFalse(any(call[:2] == ["brew", "install"] for call in self.calls))
        self.assertIn(
            ["sudo", str(self.bin / "brew"), "services", "start", "tailscale"],
            self.calls,
        )
        self.assertIn(["tailscale", "status", "--peers=false"], self.calls)
        self.assertFalse(any(call[:2] == ["tailscale", "up"] for call in self.calls))

    def test_no_login_skips_interactive_authentication(self):
        self.assert_ok(
            self.run_setup("--profile", "server", "--no-login", terminal=True)
        )
        self.assertFalse(any(call[0] == "tailscale" for call in self.calls))

    def test_install_failure_does_not_start_service(self):
        result = self.run_setup("--profile", "server", TEST_INSTALL_STATUS="7")
        self.assertEqual(result.returncode, 7)
        self.assertFalse(any(call[0] == "sudo" for call in self.calls))

    def test_inventory_failure_stops_before_changes(self):
        for args in ((), ("--profile", "desktop")):
            with self.subTest(args=args):
                result = self.run_setup(
                    *args, terminal=True, TEST_FORMULA_LIST_STATUS="7"
                )
                self.assertEqual(result.returncode, 7)
                self.assertFalse(any(call[0] == "gum" for call in self.calls))
                self.assert_no_mutations()

    def test_existing_standalone_is_reused(self):
        self.assert_ok(
            self.run_setup("--profile", "desktop", "--no-login", gui="standalone")
        )
        self.assert_no_mutations()

    def test_installed_cask_is_reused(self):
        self.assert_ok(
            self.run_setup(
                "--profile",
                "desktop",
                "--no-login",
                TEST_CASK_STATUS="0",
                TEST_INSTALL_STATUS="7",
            )
        )
        self.assert_no_mutations()

    def test_conflicting_installations_are_preserved(self):
        cases = (
            ("other app", "desktop", {"gui": "app-store-or-unknown"}),
            ("standalone app", "server", {"gui": "standalone"}),
            ("cask receipt", "server", {"TEST_CASK_STATUS": "0"}),
            ("formula", "desktop", {"TEST_FORMULA_STATUS": "0"}),
            ("manual daemon", "server", {"manual": True}),
        )
        for name, profile, options in cases:
            with self.subTest(name=name):
                result = self.run_setup("--profile", profile, **options)
                self.assertNotEqual(result.returncode, 0)
                self.assert_no_mutations()

    def test_gum_selects_profile(self):
        self.assert_ok(self.run_setup(terminal=True, TEST_CHOICE="desktop"))
        self.assertTrue(any(call[:2] == ["gum", "choose"] for call in self.calls))
        self.assertIn(["brew", "install", "--cask", "tailscale-app"], self.calls)
        self.assertIn(["open", "-a", "Tailscale"], self.calls)
        self.assertFalse(any(call[0] == "sudo" for call in self.calls))

    def test_cancelled_gum_does_not_install(self):
        result = self.run_setup(terminal=True, TEST_GUM_STATUS="130")
        self.assertEqual(result.returncode, 130)
        self.assert_no_mutations()


if __name__ == "__main__":
    unittest.main()
