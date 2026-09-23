# Private customization

Optionally clone your private-skills repository beside dotfiles. Its layout is:

```text
private-skills/
  CLAUDE.md
  AGENTS.md
  skills/
    example/
      SKILL.md
```

`ai/setup.sh` rebuilds installed instructions from the public source followed by
the matching private Markdown file. Repeated runs do not duplicate the private
tail. Missing private files produce public-only instructions. This replaces
installed instruction files; edit their source files rather than deployed copies.

`ai/sync-skills.sh` links private skill folders into the shared user skill
directory. It skips a missing checkout with a clone reminder and rejects name
collisions. Private skill contents stay in the private checkout; edits and Git
updates are immediately visible through those links.

The sync records its own links in `~/.agents/skills/.private-skill-links/`.
It prunes deleted/renamed skills and repairs those links after a checkout move
when run with the new checkout path. It never replaces an unrelated link or
directory. Exact links from the previous installer are adopted on the first
sync; run that sync before relocating an older checkout. A missing checkout
is skipped without pruning its links. Keep an empty `skills/` directory when
deliberately removing all private skills.
Run one sync at a time; the helper does not maintain a persistent lock.

Symlinks expose the entire skill directory. Keep evaluation fixtures under
`private-skills/evals/<name>/`, outside `skills/`, and generated caches out of
the skill source trees. A public skill that requires a private skill also
belongs in the private repository; optional integrations must have a standalone
fallback.

To run only these local steps, without updating community skills or CLI tools:

```fish
sh ai/sync-instructions.sh
sh ai/sync-private-skills.sh
```

Both helpers and setup honor `PRIVATE_SKILLS_DIR` for an alternate checkout:

```fish
env PRIVATE_SKILLS_DIR=/path/to/private-skills sh ai/sync-instructions.sh
```

Keep private instruction files and skill content out of this repository.

# Agent hardening

The sandbox is the boundary; permission rules, exec-policy rules and hooks are
guardrails in front of it. A guardrail that parses command text can be bypassed
by a program that builds its command at run time, so nothing below relies on one
alone.

## Shared build caches

Both sandboxes allow writes to the host's Go build cache
(`~/Library/Caches/go-build`), Go module cache (`~/go/pkg/mod`), cargo registry
and the `kache` compiler cache (`~/Library/Caches/kache`), and both allow the same
registry hosts. An agent that cannot write to a cache tends to point `GOCACHE` at
a temp directory, which builds a private multi-gigabyte cache per session, so
`ai/tests/test-codex-hardening.py` fails if either sandbox loses a cache path or
the two host lists drift apart. `CLAUDE.md` and `AGENTS.md` tell agents to build
with the defaults and to report a denied path instead of redirecting a cache.

`storage.googleapis.com` is on both lists because `proxy.golang.org` redirects
large module archives there. On the Claude side `enableWeakerNetworkIsolation`
lets sandboxed commands reach the macOS trust service; without it the `go`
command cannot verify any TLS certificate under Seatbelt and every uncached
download fails. The alternative, excluding `go` from the sandbox, would run
project code unsandboxed.

## tmux

Both sandboxes block Unix sockets, and `tmux` reaches its server through one, so
a sandboxed worker could not report to a tmux-pm PM pane. Each sandbox allows
that socket, `/private/tmp/tmux-501/default` (the path holds this user's uid;
change it on a host where `id -u` differs), and the Docker socket
`/var/run/docker.sock`, so tests can start containers such as PostgreSQL through
OrbStack. Both sandboxes resolve the symlink to OrbStack's socket. The Docker
socket hands a command the host: a container can mount the home directory,
credentials included, and reach any network host, with no approval.

Loopback TCP is open in both sandboxes (`allow_local_binding` in Codex,
`allowLocalBinding` in Claude), so tests can connect to a container's published
port on `localhost` and run their own local servers. A database driver connects
directly rather than through the network proxy, so a `localhost` domain rule
alone does not reach it. Any service listening on localhost is reachable.

## Retired files

`rsync` never deletes, so `ai/prune-retired.sh` removes from each profile the
files this repository used to install and has since deleted. A file goes only
when its path is in Git's deletion history and its content matches a version the
repository shipped. A file you or a CLI created is never touched, even at a
retired path, and a path reached through a symlink, such as `skills/`, is skipped.
A retired file installed from a version that was never committed is reported as
`Kept` and left for you to remove.

## Claude (`ai/claude/settings.json`)

- `sandbox` runs Bash under Seatbelt: writes are limited to the workspace and the
  listed toolchain caches, network to `allowedDomains`, and secret environment
  variables are removed. Directories on `PATH` stay read-only.
- `sandbox.excludedCommands` runs the git commands that create commits or tags
  (`commit`, `merge`, `rebase`, `cherry-pick`, `revert`, `tag`) outside the
  sandbox. `commit.gpgsign` signs through a program under `~/.ssh`, which the
  sandbox cannot read, so a sandboxed commit always failed. They still pass
  through the deny rules, the push guard and the auto-mode classifier.
- `env` turns `core.fsmonitor` off for git run by the agent. The sandbox blocks
  the fsmonitor socket, and git would otherwise print an IPC error on every call.
- `permissions.deny` covers the file tools and merges into the sandbox, so
  credential stores and `.env` files are unreadable by either route.
- `permissions.defaultMode` is `auto`, so the auto-mode classifier judges each
  command, including a retry outside the sandbox. `autoMode.hard_deny` adds rules
  it may never waive (pushing, reading credentials, weakening the sandbox or
  hooks); `autoMode.soft_deny` adds rules an explicit request from you can clear.
- `permissions.ask` forces a prompt, even in auto mode, for commands that
  discard work or publish a package. A retry outside the sandbox, such as a
  `gcloud compute ssh` launcher that needs `~/.ssh`, has no ask rule: the
  auto-mode classifier judges it against the `autoMode` rules above. `sudo`
  inside a quoted `gcloud compute ssh --command` is a remote command and matches
  no deny rule.
- `hooks.Notification` and `hooks.StopFailure` run `ai/hooks/notify-attention.sh`
  when approval, an MCP dialog or a background agent is waiting, or a turn ends
  with an API error. Every alert is both a Notification Center banner (OSC 777
  that Claude emits to Ghostty, through tmux) and a spoken phrase. Approval and
  failure use `voice-say` with a delivery style; a failure's phrase and style
  follow its error type (usage limit reached, busy, sign-in or billing, other). Input requests use
  the system `say`, which is also the fallback when `voice-say` is missing or
  fails. Both voices run on this Mac; `voice-say` downloads its model on first
  use, so run it once by hand on a new machine. Text is fixed, such as "Claude
  Team needs approval"; the payload's prompt and tool input are
  never read. A spent usage allowance arrives as the same `rate_limit` type as a
  busy API, so the error text is matched to tell them apart; it is never shown
  or spoken. Each session gets one alert per kind per 60 seconds. Speech is
  detached, so it never delays the banner. `touch ~/.agents/notify-mute`
  silences speech in every session and keeps the banners. Headless `-p` and SDK
  runs show no banner, but their hooks still run, so a failed turn there is
  still spoken.
- `ai/sync-claude-settings.sh` merges this file into each profile. Repository
  keys win; keys only a profile has (`model`, `effortLevel`) survive. Hooks
  merge per event: the repository's groups come first, then the profile's
  machine-local handlers. Installed handlers under `~/.agents/hooks/` belong to
  the repository, so retired ones such as `tts-notify.py` are removed. The
  previous file is kept as `settings.json.bak`.

```fish
sh ai/sync-claude-settings.sh
```

## Codex (`ai/codex/config.toml`, `ai/codex/rules/default.rules`)

Three profiles share this template: `~/.codex` (ChatGPT sign-in), `~/.codex-team`
(team account, `codex-team`) and `~/.codex-api` (API-key billing, `codex-api`).
Setup creates the directory and installs the config; sign the API profile in once
with `codex-api login --with-api-key`, which reads the key from stdin and stores
it in the Keychain.

- `default_permissions = "dev"` selects the `[permissions.dev]` profile. Codex
  ignores the profile if `sandbox_mode` or `[sandbox_workspace_write]` appears in
  any loaded layer, and ignores `network.domains` unless
  `features.network_proxy` is on. `ai/tests/test-codex-hardening.py` guards both.
- Do not add glob denies such as `"**/.env"` under `:workspace_roots`. On macOS
  they make Seatbelt refuse every directory rename in the workspace, which
  breaks cargo and npm.
- An exec-policy `allow` rule runs its command outside the sandbox without
  approval. Three exist: `xcodebuild`, `gcloud`, and the Git write subcommands.
  `ai/codex/rules/default.rules` gives the reason for each next to the rule; an
  unattended worker has no gate on any of them. `rebase`, `fetch`, `pull` and any
  `git -C`/`-c` form stay sandboxed and still need approval.
- A `deny` in the `dev` profile cannot be escalated or approved, even with
  `approvals_reviewer = "user"`. The opt-in `gcloud` profile reopens only what
  `gcloud compute ssh` needs: `~/.config/gcloud`, gcloud's own key pair
  (`~/.ssh/google_compute_engine`, read-only), its `google_compute_known_hosts`
  file, and Google API and IAP tunnel hosts. The rest of `~/.ssh`, including every
  other key and `~/.ssh/config`, stays denied. Start a
  session that runs VM maintenance with `codex -c 'default_permissions="gcloud"'`;
  every other session keeps those paths denied.
- `ai/sync-codex-config.sh` rebuilds each installed `config.toml` from the
  template plus the state Codex and its desktop app write: the model keys,
  trusted projects, plugins, marketplaces, extra MCP servers, plugin hook state
  and desktop settings. Anything else in an installed file is replaced, so a
  setting meant to last belongs in the template. Codex validates the rebuilt file
  before it is installed, and the previous one is kept as `config.toml.bak`.

```fish
sh ai/sync-codex-config.sh
```

## Per-host lockdown (`ai/host-lockdown/`)

Both agents read one root-owned policy file per machine. It outranks every
profile, and neither an agent nor a desktop app can edit it without `sudo`, so it
is where a rule belongs when it applies to one host and must not drift.

- `claude-managed-settings.json` forbids `--dangerously-skip-permissions`. It
  installs to `/Library/Application Support/ClaudeCode/managed-settings.json`.
- `codex-requirements.toml` pins Computer Use off, including the desktop app's
  install and enablement flows. It installs to `/etc/codex/requirements.toml`.

`ai/setup.sh` ends by listing what it would install and asking with
`gum confirm`, defaulting to No. It asks only from a terminal, and not again once
the files match. Leave a less sensitive host unhardened by answering No. To run
the prompt alone:

```fish
sh ai/host-lockdown/install.sh
```

Remove a file with `sudo rm` to undo it.

Check the profile without starting a session:

```fish
codex sandbox --log-denials -- cargo build
```
