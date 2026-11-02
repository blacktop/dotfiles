# macOS setup

Run `bash macos/setup.sh` to choose all preferences or review each section.
Use `--all --dry-run` to inspect the commands first.

Security hardening is a separate, optional flow:

```fish
bash macos/setup.sh --harden --all --dry-run
bash macos/setup.sh --harden --review
```

The main dotfiles installer offers this with a default-No Gum prompt.
`SETUP_MACOS_HARDENING=yes` selects it for unattended setup. Ordinary `--all`
does not include it. The hardening flow enables the application firewall and
stealth mode, requests immediate screen locking, shows filename extensions,
defaults new documents to local storage, and reuses the automatic-update
settings. Existing firewall exceptions and sharing services are preserved.

Changing screen locking may require your login password at Apple's own prompt.
Unattended runs report that step incomplete if it still needs authentication.
Gatekeeper, FileVault, SIP, and authenticated-root status are checked; failed or
unavailable checks are reported as incomplete and produce a nonzero exit.
Dry-run previews do not establish that the Mac is hardened.

Review the remaining settings yourself: FileVault recovery, Background Security
Improvements, Lockdown Mode, screen/display timeouts, unused sharing services,
stricter firewall rules, and Full Security in macOS Recovery. These choices can
affect remote access, development tools, and recovery.

[Stronghold](https://github.com/alichtman/stronghold) inspired the review, but its
legacy service commands and metadata deletion are not used. For broader,
version-specific baselines, see the maintained
[macOS Security Compliance Project](https://pages.nist.gov/macos_security/).
