dotfiles
========

My personal .files

Mostly borrowed from https://dotfiles.github.io/

Visual Studio Code is optional. Full setup prompts before installing and
configuring it. For unattended setup, opt in with
`env SETUP_VSCODE=yes ./setup.sh`; otherwise it is skipped. To install and
configure it separately, run `sh vscode/setup.sh`.

Tailscale is also optional. Full setup offers a desktop app, a headless server
daemon, or skip. Run `./tailscale/setup.sh` to configure it separately, or use
`env SETUP_TAILSCALE_PROFILE=server ./setup.sh` for a server installation.
See [Tailscale profiles and server access](tailscale/README.md).

Developer-tool telemetry defaults to off. Full setup exports the opt-outs before
running installers and applies Go's persistent opt-out after installing Go.
To apply only the privacy defaults to an existing machine:

```fish
sh privacy/setup.sh
```

This disables Go's local collection and uploads, disables Homebrew analytics, and
installs Fish defaults for supported tools. Open a new shell afterward. See the
[covered tools and limits](privacy/README.md).
