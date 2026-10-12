"""Exercise SSH configuration and rollback with real sshd, without sudo."""

import getpass
import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "harden-ssh.sh"


class HardenSSHTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(
            prefix="test-harden-ssh-", dir="/private/tmp"
        )
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.config_dir = self.root / "ssh"
        self.snippets = self.config_dir / "sshd_config.d"
        self.snippets.mkdir(parents=True)
        self.target = self.snippets / "000-local-hardening.conf"
        self.main = self.config_dir / "sshd_config"
        host_key = self.root / "host_key"
        subprocess.run(
            [
                "/usr/bin/ssh-keygen",
                "-q",
                "-t",
                "ed25519",
                "-N",
                "",
                "-f",
                str(host_key),
            ],
            check=True,
            capture_output=True,
            timeout=10,
        )
        self.main.write_text(f"Include {self.snippets}/*\nHostKey {host_key}\n")
        (self.config_dir / "crypto.conf").write_text("# Fixture policy\n")
        (self.snippets / "100-macos.conf").write_text(
            f"UsePAM yes\nInclude {self.config_dir}/crypto.conf\n"
        )
        # Redirect only paths and privilege requirements in a disposable copy.
        # Config parsing, host-key validation, file installation and rollback are real.
        self.source = (
            SCRIPT.read_text()
            .replace("/etc/ssh", str(self.config_dir))
            .replace("EUID != 0", "0 != 0")
            .replace("-o root -g wheel ", "")
        )
        self.script = self.root / "harden-ssh.sh"

    def run_script(self, *arguments):
        self.script.write_text(self.source)
        return subprocess.run(
            ["/bin/bash", str(self.script), "--user", getpass.getuser(), *arguments],
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )

    def test_dry_run_does_not_install(self):
        result = self.run_script("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.target.exists())
        self.assertIn("PasswordAuthentication no", result.stdout)

    def test_install_backup_and_repeat(self):
        original = "# Previous local policy\nPasswordAuthentication yes\n"
        self.target.write_text(original)
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        backups = list(self.config_dir.glob("sshd-hardening-backup.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), original)
        effective = (
            subprocess.run(
                ["/usr/sbin/sshd", "-G", "-f", str(self.main)],
                capture_output=True,
                text=True,
                check=True,
                timeout=10,
            )
            .stdout.lower()
            .splitlines()
        )
        self.assertIn("passwordauthentication no", effective)
        self.assertIn("kbdinteractiveauthentication no", effective)
        self.assertIn("authenticationmethods publickey", effective)
        self.assertIn("permitrootlogin no", effective)
        self.assertEqual(self.target.stat().st_mode & 0o777, 0o644)
        repeat = self.run_script()
        self.assertEqual(repeat.returncode, 0, repeat.stderr)
        self.assertIn("Already configured", repeat.stdout)
        self.assertEqual(list(self.config_dir.glob("sshd-hardening-backup.*")), backups)

    def test_failure_after_install_restores_previous_state(self):
        self.source = self.source.replace(
            '/bin/mv -f "${STAGED}" "${TARGET}"\n/usr/sbin/sshd',
            '/bin/mv -f "${STAGED}" "${TARGET}"\nfalse\n/usr/sbin/sshd',
        )
        for original in (None, "PasswordAuthentication yes\n"):
            with self.subTest(original=original):
                if original is not None:
                    self.target.write_text(original)
                result = self.run_script()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("restoring the previous configuration", result.stderr)
                self.assertEqual(
                    self.target.read_text() if self.target.exists() else None, original
                )

    def test_old_and_new_config_dump_case(self):
        original = self.source
        for source_case, target_case in (("upper", "lower"), ("lower", "upper")):
            with self.subTest(target_case=target_case):
                self.source = original.replace(
                    '/usr/sbin/sshd -G -f "${config}"',
                    '/usr/sbin/sshd -G -f "${config}"'
                    f" | /usr/bin/tr '[:{source_case}:]' '[:{target_case}:]'",
                )
                result = self.run_script("--dry-run")
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_custom_sep_compatible_algorithms_are_preserved(self):
        algorithms = "ssh-ed25519,sk-ecdsa-sha2-nistp256@openssh.com"
        (self.snippets / "000-earlier.conf").write_text(
            f"PubkeyAcceptedAlgorithms {algorithms}\n"
        )
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        effective = (
            subprocess.run(
                ["/usr/sbin/sshd", "-G", "-f", str(self.main)],
                capture_output=True,
                text=True,
                check=True,
                timeout=10,
            )
            .stdout.lower()
            .splitlines()
        )
        self.assertIn(f"pubkeyacceptedalgorithms {algorithms}", effective)
        self.assertNotIn("PubkeyAcceptedAlgorithms", self.target.read_text())

    def test_login_checks_target_native_ssh_with_the_sep_key(self):
        result = self.run_script("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("-F /dev/null", result.stdout)
        self.assertIn("-o IdentitiesOnly=yes -o IdentityAgent=none", result.stdout)
        self.assertIn("SecurityKeyProvider=/usr/lib/ssh-keychain.dylib", result.stdout)
        self.assertIn(
            f"-i ~/.ssh/id_ecdsa_sk_rk {getpass.getuser()}@MINI_LAN_IP", result.stdout
        )
        self.assertIn("-o PubkeyAuthentication=no", result.stdout)
        self.assertIn("sudo tailscale set --ssh=false", result.stdout)
        self.assertIn("FileVault", result.stdout)

    def test_missing_sep_key_cannot_fall_back_to_default_identities(self):
        result = self.run_script("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        command = next(
            line.strip()
            for line in result.stdout.splitlines()
            if line.strip().startswith("/usr/bin/ssh ") and " -i " in line
        )
        command = command.replace(
            "~/.ssh/id_ecdsa_sk_rk", str(self.root / "missing-key")
        )
        command = command.replace("MINI_LAN_IP", "192.0.2.10")
        arguments = shlex.split(command)
        effective = (
            subprocess.run(
                [arguments[0], "-G", *arguments[1:]],
                capture_output=True,
                text=True,
                check=True,
                timeout=10,
            )
            .stdout.lower()
            .splitlines()
        )
        identities = [line for line in effective if line.startswith("identityfile ")]
        self.assertEqual(identities, ["identityfile none"])
        self.assertIn(
            "pubkeyacceptedalgorithms sk-ecdsa-sha2-nistp256@openssh.com", effective
        )

    def test_conflicting_or_custom_config_is_rejected_before_install(self):
        for extra in (
            "PasswordAuthentication yes\n",
            "AllowUsers someone_else\n",
            "PubkeyAcceptedAlgorithms ssh-ed25519\n",
            "Match Address 192.0.2.0/24\n  PasswordAuthentication yes\n",
            "Match=Address 192.0.2.0/24\n  PasswordAuthentication yes\n",
            "Include /nonstandard/config\n",
            "Include=/nonstandard/config\n",
            f"Include {self.config_dir}/crypto.conf /nonstandard/config\n",
            "NotAnSSHDirective yes\n",
        ):
            with self.subTest(extra=extra):
                (self.snippets / "000-earlier.conf").write_text(extra)
                result = self.run_script()
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.target.exists())

    def test_unknown_account_is_rejected(self):
        result = self.run_script("--user", "no-such-ssh-hardening-account")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unknown account", result.stderr)
        self.assertFalse(self.target.exists())


if __name__ == "__main__":
    unittest.main()
