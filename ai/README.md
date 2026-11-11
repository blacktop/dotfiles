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

# Agent permissions

The filesystem sandbox limits writes and access to credential stores. Network
destinations are controlled by the host firewall: Codex uses direct networking,
and Claude's sandbox proxy allows all domains without TLS interception.
Permission rules and hooks guard destructive Git operations and remote pushes.
These command guards do not interpret arbitrary programs that construct Git calls.

## Shared build caches

The [Rust/Go path inventory](dev-paths.md) documents shared caches, state, sockets,
workspace/temp outputs and installation-only destinations with upstream sources.
`dev-cache-paths.json` is checked against both agent templates so their standard
Rust/Go tool allowances stay aligned. This includes audit/deny/vet, Miri, nextest,
gopls and kache's optional daemon socket. Native temp discovery remains host-local.

Both sandboxes allow writes to the host's Go build cache
(`~/Library/Caches/go-build`), Staticcheck cache (`~/Library/Caches/staticcheck`),
Go module cache (`~/go/pkg/mod`), cargo registry,
the `kache` compiler cache (`~/Library/Caches/kache`), Zig's shared cache
(`~/.cache/zig`), prek's hook environments and log (`~/.cache/prek`; without
it `prek` cannot even open its log file), and Bun's package cache
(`~/.bun/install/cache`; `bunx`, used by tmux-pm's `ccusage` checks, fails its
temp-directory check without it). An agent that cannot write to a cache tends to point `GOCACHE` at
a temp directory, which builds a private multi-gigabyte cache per session, so
`ai/tests/test-codex-hardening.py` checks the shared cache paths and unrestricted
domain policy. `CLAUDE.md` and `AGENTS.md` tell agents to build
with the defaults and to report a denied path instead of redirecting a cache.

Registries, custom module hosts and download redirects do not need individual
agent allowances. On the Claude side `enableWeakerNetworkIsolation`
lets sandboxed commands reach the macOS trust service; without it the `go`
command cannot verify any TLS certificate under Seatbelt and every uncached
download fails.

Gitignored private source is still accessible by explicit path, but ordinary
Git worktrees contain only tracked files. Search tools also commonly skip ignored
files unless given a scoped override. Before building a worker worktree, make
the required private source available through the project's private-source setup;
do not force-add it or indiscriminately copy all ignored files. Go's `mod tidy`
loads imports behind optional build tags too, so missing private packages can
break tidy even when an ordinary build passes.

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

- `sandbox` runs Bash under Seatbelt: writes are limited to the workspace and
  the listed toolchain caches. It omits `~/.Trash`: Claude drops that path from
  `allowWrite` (observed 2026-10-02), so `trash` relies on its exclusion below;
  `allowedDomains: ["*"]` allows every network destination through its forwarding
  proxy. HTTPS is not intercepted. Listed secret environment variables are
  removed; the dedicated `GH_TOKEN` is inherited directly (see GitHub CLI below).
  Directories on `PATH` stay read-only.
  On macOS, the sync script also discovers the native per-user temporary directory
  with `getconf DARWIN_USER_TEMP_DIR` and adds its canonical path to installed
  settings. This supports tools using the native temp location without storing
  a machine-specific `/var/folders` path in the shared template.
- `sandbox.excludedCommands` runs the git commands that create commits or tags
  (`commit`, `merge`, `rebase`, `cherry-pick`, `revert`, `tag`) outside the
  sandbox. `commit.gpgsign` signs through a program under `~/.ssh`, which the
  sandbox cannot read, so a sandboxed commit always failed. They still pass
  through the deny rules, the push guard and the auto-mode classifier.
- The read-only host admission check `/opt/homebrew/bin/headroom` also runs
  outside Seatbelt when called directly. This makes its swap and kernel memory
  pressure readings available. Claude matches the submitted command text, so
  calling it from inside a sandboxed script does not inherit this exclusion.
- Eligible branch and worktree commands, the installed tmux-pm
  `worktree-lifecycle.sh`, and `trash` are also excluded from Seatbelt. Claude's
  built-in write denies cannot be lifted with `allowWrite`; they can prevent
  creating/deleting worktree metadata or removing branch tracking config, and
  sandboxed `trash` fails because `~/.Trash` is not writable. A call leaves the
  sandbox only when every command in it matches an exclusion and it has no
  redirect, `cd` or `$(...)`. `hooks/block-chained-trash.py` therefore blocks any
  `trash` that is not its own call, and `$TMPDIR` paths, because the unsandboxed
  call sees the native temporary directory. These targeted exclusions follow
  [Claude's documented fallback](https://code.claude.com/docs/en/sandboxing).
  They keep Bash permission checks and the Git hook, but those commands and their
  children do not have OS filesystem/network isolation. Invoke the installed
  helper directly; unmatched wrappers can use the normal authorized unsandboxed
  retry. No blanket `git`, shell, or filesystem-isolation exemption is added.
  Claude Code 2.1.282 rejects Git global `-C` and `-c` options before matching
  exclusion patterns; even the configured `git -C * branch *` patterns cannot
  exempt those calls. Compound calls require every segment to qualify as well.
  After a Seatbelt denial of an authorized local operation, retry that exact
  operation with the Bash tool input `dangerouslyDisableSandbox: true` (not a
  shell flag or environment variable). `allowUnsandboxedCommands` already permits
  this route; no settings change or restart is needed. Keep the retry to the
  intended operation. It still goes through the normal permission flow.
- The shared Git guard permits `worktree prune`, non-forced `worktree remove`,
  and merged-branch deletion with `branch -d`, including chains and `git -C`.
  Prune removes stale registrations: check that missing trees were intentionally
  removed rather than temporarily unmounted. Pushes, forced removal/deletion,
  hard reset, and destructive clean remain blocked. If removal deletes a checkout
  but fails to delete its registration, prune and retry retirement; the lifecycle
  helper recovers the `retiring` record without inspecting a missing directory.
- A sandbox error, a Git-hook block, and an auto-mode classifier denial are
  separate gates. Exclusions address the sandbox only. They do not override a
  blocking hook or an explicit deny rule, and matching in a live Claude Bash
  session still needs verification after installation.
- For a Claude classifier denial, use `/permissions` → **Recently denied** →
  select the action → `r` to retry with manual approval. Auto mode otherwise
  prompts after three consecutive or twenty total classifier denials; these
  thresholds cannot be configured, and headless `-p` sessions abort instead of
  prompting. A content-scoped `permissions.ask` rule forces a prompt before the
  classifier; `Bash(dangerouslyDisableSandbox:true)` can require human approval
  for explicit unsandboxed retries. See [permission modes](https://code.claude.com/docs/en/permission-modes)
  and [sandbox retries](https://code.claude.com/docs/en/sandboxing).
- For Codex automatic-review denials, `/approve` grants one exact-action retry;
  the reviewer still evaluates it under policy. For human-reviewed escalations
  from the outset, use `approval_policy = "on-request"` and
  `approvals_reviewer = "user"`. Managed restrictions still apply. This is an
  operator choice for an attended session, not a reason to disable sandboxing or
  change every unattended worker. See [Codex Auto-review](https://learn.chatgpt.com/docs/sandboxing/auto-review).
- `env` turns `core.fsmonitor` off for git run by the agent. The sandbox blocks
  the fsmonitor socket, and git would otherwise print an IPC error on every call.
- `permissions.deny` covers the file tools and merges into the sandbox, so
  credential stores and `.env` files are unreadable by either route.
- `permissions.defaultMode` is `auto`, so the auto-mode classifier judges each
  command, including a retry outside the sandbox. `autoMode.hard_deny` adds rules
  it may never waive (pushing, reading credentials, weakening the sandbox or
  hooks); `autoMode.soft_deny` adds rules an explicit request from you can clear.
- `fish/functions/claude.fish` sets `CLAUDE_CODE_AUTO_MODE_SERVER=0` for every
  profile except `claude-team`, so the classifier runs locally (Sonnet by default,
  counted as usage) as it did with telemetry off before Claude Code 2.1.282.
  `claude-team` keeps the server-side check, which runs inside its Mythos requests
  at no charge; the local classifier's Sonnet requests would break that account's
  Mythos-only rule. The variable only reaches sessions started from fish.
- `permissions.ask` forces a prompt, even in auto mode, for commands that
  discard work or publish a package. A retry outside the sandbox, such as a
  `gcloud compute ssh` launcher that needs `~/.ssh`, has no ask rule: the
  auto-mode classifier judges it against the `autoMode` rules above. `sudo`
  inside a quoted `gcloud compute ssh --command` is a remote command and matches
  no deny rule.
- `hooks.Notification` and `hooks.StopFailure` run `ai/hooks/notify-attention.sh`
  when approval, an MCP dialog or a background agent is waiting, or a turn ends
  with an API error. Every alert is both a macOS notification posted by
  `notify-pane.sh` (below) and a spoken phrase. Approval and
  failure use `voice-say` with a delivery style; a failure's phrase and style
  follow its error type (usage limit reached, busy, sign-in or billing, other). Input requests use
  the system `say`, which is also the fallback when `voice-say` is missing or
  fails. Both voices run on this Mac; `voice-say` downloads its model on first
  use, so run it once by hand on a new machine. Text is fixed, such as "Claude
  Team needs approval"; the payload's prompt and tool input are
  never read. A spent usage allowance arrives as the same `rate_limit` type as a
  busy API, so the error text is matched to tell them apart; it is never shown
  or spoken. Each session gets one alert per kind per 60 seconds. Speech is
  detached, so it never delays the notification. `touch ~/.agents/notify-mute`
  silences speech in every session and keeps the notifications.
- `hooks.PostToolUse` on `mcp__mcp-tts__.*` (and the Codex `^mcp__mcp_tts__`
  hook in `codex/config.toml`) runs `ai/hooks/notify-pane.sh`, so every spoken
  alert also leaves a native Voice notification: title "agent account ·
  project", subtitle the tmux pane (`tmux aarch64-rs:3.1 (%52)`), message the
  spoken text. Each pane keeps one notification. The hook also passes an
  absolute, existing working directory as `--zed-project`. Clicking selects
  the pane in a client already showing its session, then asks Zed to open or
  focus the full project path. Voice falls back to the terminal app if Zed
  fails; it never switches, attaches or detaches a tmux client. Claude runs
  hooks in its own pane, so `TMUX_PANE`
  names it; Codex runs hooks in a shared daemon, so its pane is the one in the
  session's directory running `codex`, and several such panes are listed rather
  than guessed. The hook passes the resolved pane and tmux socket to
  `voice-notify`; Voice authenticates the connection and handles the click.
  Ambiguous or absent panes can still open the project, without a tmux target.
  If Voice rejects the optional project path, the hook posts once without it.
  Zed chooses among duplicate windows of the same project, and a hidden terminal
  tab may still need manual selection. Install the updated signed Voice app
  and CLI together, approve Voice's notification prompt once, and choose Persistent under
  System Settings → Notifications → Voice → Alert Style. Phone push is disabled.
- `ai/sync-claude-settings.sh` merges this file into each profile. Repository
  keys win; keys only a profile has (`model`, `effortLevel`) survive. Hooks
  merge per event: the repository's groups come first, then the profile's
  machine-local handlers. Installed handlers under `~/.agents/hooks/` belong to
  the repository, so retired ones such as `tts-notify.py` are removed. The
  previous file is kept as `settings.json.bak`.

```fish
sh ai/sync-claude-settings.sh
```

### GitHub CLI

`gh` runs inside the sandbox with a token of its own, never your `gh auth login`
token. `fish/functions/claude.fish` reads the dedicated token from
the Keychain into the `claude` process and points `GH_CONFIG_DIR` at
`~/.config/gh-claude`, which need not exist; gh stops when it cannot read
`~/.config/gh`, which stays denied.

There is no token substitution or TLS interception. Commands inside and outside
the sandbox inherit the real dedicated token, as do hooks and MCP servers, so
scope it narrowly. Network policy does not confine it to a particular hostname.

Create a fine-grained token at
<https://github.com/settings/personal-access-tokens/new> for your account, with a
90-day expiry, the repositories Claude should reach, read-only Contents, Actions,
Checks and Commit statuses, and read-write Issues and Pull requests. Leave
Administration, Workflows, Secrets, Variables and Gists off. Read-only Contents
means Claude cannot push, merge or publish a release. One token covers one
owner. Store it in the Keychain; `-w` last prompts for the value, which keeps it
out of shell history:

```fish
security add-generic-password -U -a $USER -s claude-gh-token -w
ln -sf (pwd)/fish/functions/claude.fish ~/.config/fish/functions/
```

In a new session `gh api user --jq .login` verifies access without printing the token.

## Codex (`ai/codex/config.toml`, `ai/codex/rules/default.rules`)

Three profiles share this template: `~/.codex` (ChatGPT sign-in), `~/.codex-team`
(team account, `codex-team`) and `~/.codex-api` (API-key billing, `codex-api`).
Setup creates the directory and installs the config; sign the API profile in once
with `codex-api login --with-api-key`, which reads the key from stdin and stores
it in the Keychain.

All three forward the calling Rex terminal's context to mcp-tts and opt into
`--rex-tab-label`. Use an mcp-tts build that supports that flag, then restart an
existing Codex conversation after changing the MCP launch configuration. During
real playback, mcp-tts prefixes the exact tab label with `🔊 ` and restores the
original when the last speaker finishes. It preserves manual renames it detects;
Rex's label API cannot make the final check and restore atomic. Native activity
records remain available under Rex's **Settings → Notifications → Program
Activity**, but they can share Codex's existing generic working indicator. See
the [Rex activity settings](https://www.superlogical.com/rex/docs/reference/mac-settings#program-activity).

- `default_permissions = "dev"` selects the `[permissions.dev]` profile. Codex
  ignores the profile if `sandbox_mode` or `[sandbox_workspace_write]` appears in
  any loaded layer. `network.enabled = true` with `features.network_proxy = false`
  provides direct network access; domain tables are absent. The host firewall
  controls destinations. `ai/tests/test-codex-hardening.py` checks this policy.
- The `dev` profile allows writes to `~/.Trash` so `trash` can move workspace
  files there for recoverable deletion.
- Local `.git` metadata is writable so staging, committing, ref packing and
  merge bookkeeping work normally. Destructive Git operations and pushes are
  guarded at the command level; this is not branch-level OS isolation.
  `.codex` and `.agents` remain read-only. Never add `.git/<child>` filesystem
  rules under `:workspace_roots`: linked worktrees use a `.git` pointer file,
  and those child paths prevent Seatbelt from starting. Linked-worktree
  launchers must pass `--add-dir` with `git rev-parse --path-format=absolute
  --git-common-dir` and, when different, `git rev-parse --absolute-git-dir`
  so Git can update shared metadata and the current worktree's own index/HEAD.
  `rexurrect-launch` does this for every Codex account launcher, so a session
  started in any linked worktree can stage and commit.
- The opt-in `pm` profile (`codex-pm`) extends `dev` with write access to the
  tmux-pm lane root, `~/.local/share/tmux-pm/worktrees`, so a PM can create,
  check and retire lanes. Workers stay on `dev`: one lane cannot write another.
  A PM that coordinates more than one repository also passes `--add-dir <repo>`
  for each additional one. `claude-pm` is the Claude equivalent; it adds the
  lane root with `--add-dir` instead of a global `allowWrite` entry.
- `sh ai/sync.sh` applies hooks, Claude settings, Codex config, instructions
  and the launcher without installing anything; `ai/setup.sh` calls it. New
  fish functions are linked by `fish/setup.sh`.
- YOLO mode is a per-host opt-in for a machine meant to run unrestricted
  agents. `ai/setup.sh` asks with a `gum` prompt that defaults to No and records
  a Yes in `~/.agents/yolo`; `ai/sync.sh` honours that marker without asking.
  With it, Claude gets `bypassPermissions` and no sandbox; Codex gets
  `:danger-full-access`, `approval_policy = "never"` and no exec rules. Plain
  `git push`, force-add, shell-config edits and all of `~/.ssh` are allowed.
  Guards for irreversible or outward-facing actions stay, as Claude deny rules
  and in the Codex command hook: `rm` (use `trash`), `sudo`, `mkfs`, `dd`,
  `diskutil` erase, piping a download into a shell, force-push,
  `git reset --hard`, publishing, `gh` release/repo deletion, environment dumps,
  and reads of Keychains, GnuPG, agent `auth.json`, `.netrc`, `.git-credentials`
  and `locals.fish`. With no sandbox these secret guards match command text
  only; they stop casual reads, not a determined process. Notification hooks, MCP servers and instructions are
  unchanged, and host lockdown is skipped. Delete the marker and run
  `sh ai/sync.sh` to restore hardening.
- The shared Git guard blocks pushes (including aliases, `send-pack` and
  `http-push`), hard resets, non-dry-run cleaning, forced branch/worktree
  operations, stash destruction and worktree-content restores.
  Ordinary commits, ref packing, local merges, new branches, dry runs, unstaging,
  safe branch deletion, stale worktree pruning and non-forced removal of clean
  worktrees remain allowed.
  The PM owns integration and retirement. These shell guards cover recognized
  commands; they do not interpret arbitrary programs that construct Git calls.
- This local policy follows the productive workspace boundary described in
  [OpenAI's approval guidance](https://learn.chatgpt.com/docs/agent-approvals-security),
  with targeted restrictions for the operations we want to reserve for the user.
  [Claude's auto-mode guidance](https://code.claude.com/docs/en/auto-mode-config)
  recommends explicit ask/deny boundaries and allow exceptions for routine work;
  [its worktree documentation](https://code.claude.com/docs/en/worktrees) explicitly
  allows writes to the shared Git metadata so sandboxed commits can work.
- Do not add glob denies such as `"**/.env"` under `:workspace_roots`. On macOS
  they make Seatbelt refuse every directory rename in the workspace, which
  breaks cargo and npm.
- Exec-policy `allow` rules approve matching commands, but do not prove host
  execution. Codex 0.162.0 retains the sandbox whenever the active filesystem
  profile contains a denied-read path, including during `require_escalated`.
  The `dev` profile's credential-store denies therefore keep these commands
  sandboxed. An exact `/bin/ps` probe on the same daemon failed under `dev` and
  succeeded with an explicit one-command host policy. Restarting with the same
  profile does not remove this constraint. Keep the credential restrictions and
  use the tool's permitted reviewed retry for an authorized host-only operation.
  Hand execution to the user only for a required human interaction or an
  observed restriction with no permitted agent-side recovery; include the exact
  command and denial.
  Codex 0.163's `dev` profile still denies full-host `ps` and the kernel pressure
  sysctl, although `memory_pressure -Q` works. All three exact read-only host
  requests succeed. Do not exempt the arbitrary-argv guarded-job runner: it
  needs separately authorized host execution, not a broader interpreter rule.
  See the [versioned escalation implementation](https://github.com/openai/codex/blob/rust-v0.162.0/codex-rs/core/src/tools/sandboxing.rs#L251-L311)
  and [upstream issue](https://github.com/openai/codex/issues/38318).
- The shared Swift allow rules cover `xcodebuild`, `swiftc`, `swift build`, `swift test`,
  and `swift package resolve`, `describe`, `dump-package`, and `show-dependencies`.
  They accept the bare command or `/usr/bin` path, plus the normal
  `xcrun <tool>` form. Xcode, SwiftPM and compiler macros can start their own
  macOS sandbox, which fails under an existing Seatbelt sandbox. When the active
  policy permits host execution, these allowances trust the selected project's
  manifests, plugins, build phases and tests with host access. An arbitrary
  `swift` script, `swift run`, other `xcrun` tools,
  `just`, and shell wrappers are not covered. Put options after the selected
  command, such as `swift build --package-path /path/to/project`. Preserve a
  repository's required build wrapper; use an exact project rule or an approved
  host retry when it needs to leave the sandbox. See [Codex command rules](https://learn.chatgpt.com/docs/agent-configuration/rules).
- The exact `/opt/homebrew/bin/headroom` binary has an allow rule for reading
  swap and kernel memory pressure for agent admission. Under `dev`, those fields
  and thermal state can still be unavailable because the read-deny restrictions
  retain Seatbelt.
  Invoke it directly by its absolute path; the rule does not cover PATH
  lookalikes or shell wrappers.
- The public entry points of installed local skills have exact Codex command
  allowances, including every normal tmux-pm lifecycle, gate, dispatch, and
  checkup helper. Direct invocation and the documented shell, Python, or Node
  forms are covered. Internal lane modules, arbitrary interpreters, and the
  generic guarded-job runner are not host escape hatches; the latter still
  needs an authorized payload and its existing host-resource contract. These
  command approvals do not lift the selected filesystem or credential policy.
- The other allow rules remain `gcloud`, the Git write subcommands, and
  staging/committing with exactly `git -c core.fsmonitor=false`.
  `ai/codex/rules/default.rules` gives the reason for each next to the rule; an
  unattended worker has no gate on any of them. `rebase`, `fetch`, `pull`,
  `git -C`, and other `-c` forms stay sandboxed and still need approval.
- Workers stage explicit owned paths with `git add -- <paths>`. Approved unsigned
  checkpoints use `git commit --no-gpg-sign`; signed checkpoints use `git commit
  -S`. The automatic-review policy allows the necessary index/object/ref/reflog
  writes in the worktree's Git common directory, even outside its source root.
  Workers own their checkpoint branch; the PM owns integration and retirement.
  These are workflow boundaries: the broad Git write rules do not enforce branch
  isolation. Test actual worker staging and committing before expensive work;
  matching an exec-policy rule alone does not prove OS access.
- The opt-in `gcloud` permission profile inherits direct network access and allows
  arbitrary Unix sockets, including Terraform's random `plugin*` sockets in the native
  macOS temporary directory. `allow_local_binding` alone does not allow those
  sockets. No `PLUGIN_UNIX_SOCKET_DIR` override is needed. This uses the documented
  [`dangerously_allow_all_unix_sockets` setting](https://learn.chatgpt.com/docs/permissions).
  These network grants apply to every process in a `gcloud` session, not just
  executables named `gcloud` or `terraform`.
- `gcloud` also permits writes to `~/.config/gcloud`, its own SSH key pair and
  `google_compute_known_hosts`, `~/.terraform.d`, `~/.terraformrc`, and
  `~/Library/Application Support/io.terraform`. Terraform's standard user paths
  follow [HashiCorp's CLI configuration documentation](https://developer.hashicorp.com/terraform/cli/config/config-file).
  Other SSH keys and unrelated secret stores remain denied. Workspace writes,
  shared build caches, and the Git push/destructive-operation guards stay in place.
  Cloud task authorization and explicit deployment/review holds still apply.
- Select this permission profile with `codex -c 'default_permissions="gcloud"'`.
  To resume, use `codex -c 'default_permissions="gcloud"' resume SESSION_ID`.
  `-p gcloud` selects a separate configuration file and is not the same option.
  Restart/resume the agent after syncing changes; an escalation in an old session
  does not prove it loaded the new policy. DarwinDB's mock checks can then run as
  `bash scripts/check-terraform.sh root application` with its pinned Terraform
  on PATH, without relocating sockets or caches.
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
