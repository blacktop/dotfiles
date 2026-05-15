## Language Guidance

### Rust

- Do NOT use unwraps or anything that can panic in Rust code, handle errors. Obviously in tests unwraps and panics are fine!
- In Rust code I prefer using `crate::` to `super::`; please don't use `super::`. If you see a lingering `super::` from someone else clean it up.
- Avoid `pub use` on imports unless you are re-exposing a dependency so downstream consumers do not have to depend on it directly.
- Skip global state via `lazy_static!`, `Once`, or similar; prefer passing explicit context structs for any shared state.

#### Rust Workflow Checklist

1. Run `cargo fmt`.
1. Run `cargo clippy --all --benches --tests --examples --all-features` and address warnings.
1. Execute the relevant `cargo test` or `just` targets to cover unit and end-to-end paths.

## Final Handoff

Before finishing a task:

1. Confirm all touched tests or commands were run and passed (list them if asked).
1. Summarize changes with file and line references.
1. Call out any TODOs, follow-up work, or uncertainties so the user is never surprised later.

## Host Defaults

- User-facing terminal examples should assume macOS with Homebrew and Fish unless the target is explicitly Linux, a container, or a remote host.
- Use Fish-compatible syntax for copy/paste snippets. Prefer `env NAME=value command` for one-shot environment variables.
- Prefer macOS-native tools in examples: `brew`, `open`, `pbcopy`/`pbpaste`, `security`, and `xcode-select`. Avoid `apt`, `yum`, `systemctl`, `xdg-open`, or Linux clipboard tools unless the target environment requires them.
- Homebrew is available under the Apple Silicon prefix when an absolute path is necessary; prefer `brew --prefix` in reusable commands.

## Shell Examples

The user's interactive shell is Fish. When giving commands for the user to copy/paste into their terminal, prefer Fish-compatible syntax:

- Use `set -gx NAME value` for exported variables, or `env NAME=value command` for one command.
- Use Fish command substitution: `(command)`, not `$(command)`.
- Avoid Bash-only snippets in interactive examples: `export NAME=value`, `VAR=value command`, `source venv/bin/activate`, arrays, heredocs, and `for x in ...; do ...; done`.
- If a snippet is specifically a script file, use Bash/sh with a shebang and say to run it as `bash script.sh` or `sh script.sh`.
- Agent-executed commands may still use the harness shell; this guidance is for user-facing copy/paste examples.

### TypeScript

- In TypeScript codebases NEVER, EVER use `any` we are better than that. And if the app is for a browser, assume we use all modern browsers unless otherwise specified, we don't need most polyfills. Similarly, using `as` is bad and we should just use the types given everywhere.

### Python

- **Python repos standard**. We use `uv` and `pyproject.toml` in all Python repos. Prefer `uv sync` for env and dependency resolution. Do not introduce `pip` venvs, Poetry, or `requirements.txt` unless asked.

## Dependencies & External APIs

- If you need to add a new dependency to a project to solve an issue, search the web and find the best, most maintained option. Something most other folks use with the best exposed API. We don't want to be in a situation where we are using an unmaintained dependency, that no one else relies on.

## Apple Platform Artifacts

For Apple iOS/macOS research and tooling (`ipsw`, DSC/dyld_shared_cache work,
kernelcache/KC analysis, extracted firmware), start artifact discovery in
`~/Documents/IPSWs`. Do not scan the whole filesystem looking for IPSWs,
extracted DSCs, or kernelcaches; search that directory first and ask before
widening the search.

## Secrets & Local Shell State

- Never inspect, print, dump, or verify environment variables or shell-local configuration to confirm credentials or setup.
- Never read files like `locals.fish`, `.zshrc`, `.zprofile`, `.bashrc`, `.bash_profile`, `config.fish`, or similar shell startup or local secret-bearing files unless the user explicitly asks for that file to be edited.
- Do not run commands like `env`, `printenv`, `set`, `export`, or equivalent probes for this purpose.
- If authentication or local setup may be the issue, run the target tool or command directly and report the failure without probing the environment first.

## HTML Artifacts

When a task warrants a self-contained HTML artifact (interactive UI, ≥3-axis comparison, status snapshot, throwaway editor), use the `html-artifacts` skill — invoke by name; Codex has no `/artifact` slash command, so state intent (durable vs. throwaway, voice vs. silent) in the prompt. Output paths: `docs/.ai/artifacts/<topic>.html` (durable; `git add -f` to track since `docs/.ai/` is globally ignored) or `docs/.ai/tools/<topic>.html` (throwaway). Voice summaries (opt-in) go through the `speak` skill, never `tts-notify.py` directly. Format rules and self-check live in the skill body.
