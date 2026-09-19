## Language Guidance

### Rust

- Follow the repository's pinned toolchain, MSRV, target matrix, feature matrix,
  CI commands, and local guidance before applying global defaults.
- Do NOT use unwraps or anything that can panic in production Rust code; handle
  errors. Tests may use panics when they make failures clearer.
- In Rust code I prefer using `crate::` to `super::`; please don't use `super::`. If you see a lingering `super::` from someone else clean it up.
- Avoid `pub use` on imports unless you are re-exposing a dependency so downstream consumers do not have to depend on it directly.
- Skip global state via `lazy_static!`, `Once`, or similar; prefer passing explicit context structs for any shared state.
- Treat indexing, integer arithmetic, recursion, lock poisoning, and task/thread
  joins as panic or exhaustion surfaces. Use checked APIs and explicit bounds
  when values are externally controlled.
- Do not use `debug_assert!` to enforce input validation or an invariant needed
  for correct release behavior.
- Bound external inputs, allocation sizes, recursion depth, concurrency, queues,
  caches, connection pools, retries, and external I/O with explicit timeouts.
- Keep `unsafe` blocks small and document each with a `// SAFETY:` argument that
  covers the relevant validity, aliasing, lifetime, alignment, thread-safety,
  ownership, and FFI unwind invariants. Require explicit unsafe blocks inside
  unsafe functions (`unsafe_op_in_unsafe_fn`).

#### Rust Failure Model

- Decide `panic = "unwind"` versus `"abort"` at the final binary/deployment
  boundary. Never impose either strategy on a reusable library.
- Use `catch_unwind` only at an explicit isolation boundary with a defined
  `UnwindSafe` contract. It is not general recovery and cannot catch aborting
  failures.
- Panic hooks run for panics under both unwind and abort strategies, but not for
  arbitrary process termination. They are observability only: keep them bounded
  and non-blocking, redact secrets and raw user data, and never rely on them for
  correctness or cleanup.
- Observe every spawned task/thread failure. Do not let a worker panic silently
  leave a service partially degraded.
- Long-running services must define graceful shutdown, readiness versus
  liveness, backpressure, and dependency-failure behavior.
- musl, alternative allocators/linkers, sandboxing, LTO, and
  `target-cpu=native` require target-specific evidence; they are not universal
  Rust defaults.

#### Rust Workflow Checklist

1. Discover and run the repository's CI/`just` checks and intended feature/target
   combinations. They override the fallbacks below.
1. Run `cargo fmt`.
1. Run `cargo clippy --workspace --all-targets --all-features -- -D warnings`
   unless the project has mutually exclusive features or a narrower canonical
   command.
1. Execute the relevant `cargo test` or `just` targets for unit, integration,
   doc, and end-to-end behavior.
1. Add risk-based checks: release-mode tests for optimization-sensitive,
   arithmetic-heavy, unsafe, FFI, or `cfg(debug_assertions)` code; targeted Miri
   for unsafe code; fuzz/property tests for parsers and untrusted inputs; and
   `cargo deny`/`cargo vet` when configured. Test a built binary in a subprocess
   when panic-strategy behavior matters because the Rust test harness does not
   honor `panic = "abort"`.

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
kernelcache/KC analysis, extracted firmware), start artifact discovery in the
directory named by the `$APPLE_FIRMWARE_DIR` environment variable (resolve it
with `echo $APPLE_FIRMWARE_DIR`; it currently points at `~/Apple`). Do not scan
the whole filesystem looking for IPSWs, extracted DSCs, or kernelcaches; search
that directory first and ask before widening the search.

## Secrets & Local Shell State

- Never inspect, print, dump, or verify environment variables or shell-local configuration to confirm credentials or setup.
- Never read files like `locals.fish`, `.zshrc`, `.zprofile`, `.bashrc`, `.bash_profile`, `config.fish`, or similar shell startup or local secret-bearing files unless the user explicitly asks for that file to be edited.
- Do not run commands like `env`, `printenv`, `set`, `export`, or equivalent probes for this purpose.
- If authentication or local setup may be the issue, run the target tool or command directly and report the failure without probing the environment first.
