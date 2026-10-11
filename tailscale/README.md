# Tailscale

Run `./tailscale/setup.sh` from the dotfiles checkout. Gum offers these profiles:

| Profile | Installation | Intended use |
| --- | --- | --- |
| `server` | Homebrew `tailscale` formula and a root launchd service | A headless Mac mini running local models, agent work, and media services |
| `desktop` | Homebrew `tailscale-app` cask | A Mac used through a desktop login, with the standalone app's automatic updates |
| `skip` | No changes | Keep the current installation |

The server daemon starts at boot after macOS can access its startup disk. It can
host Tailscale SSH, but it does not have the Mac app's GUI or automatic updater.
The desktop app is Tailscale's recommended general-purpose macOS installation.
See the official [variant comparison](https://tailscale.com/docs/concepts/macos-variants)
and Homebrew's [daemon](https://formulae.brew.sh/formula/tailscale) and
[app](https://formulae.brew.sh/cask/tailscale-app) packages.

Choose a profile directly in the Mac's Terminal:

```fish
./tailscale/setup.sh --profile server
```

For full dotfiles setup, use `env SETUP_TAILSCALE_PROFILE=server ./setup.sh`.
Without a terminal, an unspecified profile is skipped. An explicitly selected
profile installs its software, but authentication stays interactive. Use
`--no-login` to defer sign-in even when running from a terminal. Complete a
server's sign-in later with `sudo tailscale up`.

Setup preserves an existing connection and refuses to replace another variant
or a manually installed daemon. To migrate, use Tailscale's
[switching instructions](https://tailscale.com/docs/concepts/macos-variants).

## Access to the Mac mini

Keep LLM APIs and media administration endpoints bound to localhost or the
Tailscale address. Use [Tailscale Serve](https://tailscale.com/docs/features/tailscale-serve)
when an HTTP service needs a private HTTPS endpoint. Define
[access grants](https://tailscale.com/docs/features/access-control/grants) for the
specific people, devices, and ports that need access; a new tailnet's default
policy is permissive. Keep application authentication enabled too.

Once those rules are in place, optionally enable
[Tailscale SSH](https://tailscale.com/docs/features/tailscale-ssh):

```fish
sudo tailscale set --ssh
```

This changes how SSH connections to the Tailscale address are handled and can
interrupt an existing SSH session. Setup does not enable SSH, public Funnel
access, subnet routing, or exit-node service automatically.

For stronger enrollment control, choose
[device approval](https://tailscale.com/docs/features/access-control/device-management/device-approval)
or [Tailnet Lock](https://tailscale.com/docs/features/tailnet-lock). They cannot
both be enabled. Keep FileVault on, retain its recovery information, and test
remote access after a full reboot before leaving the mini unattended. Avoid
enabling the separate offline PF profile until the required clients and media
traffic have been tested.

Update the daemon and restart it during a maintenance window:

```fish
brew upgrade tailscale
sudo brew services restart tailscale
```

Verify the connection from another trusted device using `tailscale ping` and
then exercise the actual LLM or media endpoint. A successful local setup does
not establish that the tailnet policy or service listeners permit that access.
