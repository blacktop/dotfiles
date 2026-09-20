# Global Development Standards

Global instructions for all projects. Project-specific CLAUDE.md files override these defaults.

- Prefer Exa AI (`mcp__exa__web_search_exa`) over `WebSearch` for all web searches
- Use skills proactively when they match the task — suggest relevant ones, don't block on them

## Plan Mode

- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.

## Philosophy

- **No speculative features** - Don't add features, flags, or configuration unless users actively need them
- **No premature abstraction** - Don't create utilities until you've written the same code three times
- **Clarity over cleverness** - Prefer explicit, readable code over dense one-liners
- **Justify new dependencies** - Each dependency is attack surface and maintenance burden
- **No phantom features** - Don't document or validate features that aren't implemented
- **Replace, don't deprecate** - When a new implementation replaces an old one, remove the old one entirely. No backward-compatible shims, dual config formats, or migration paths. Proactively flag dead code — it adds maintenance burden and misleads both developers and LLMs.
- **Verify at every level** - Set up automated guardrails (linters, type checkers, pre-commit hooks, tests) as the first step, not an afterthought. Prefer structure-aware tools (ast-grep, LSPs, compilers) over text pattern matching. Review your own output critically. Every layer catches what the others miss.
- **Bias toward action** - Decide and move for anything easily reversed; state your assumption so the reasoning is visible. Ask before committing to interfaces, data models, architecture, or destructive/write operations on external services.
- **Finish the job** - Don't stop at the minimum that technically satisfies the request. Handle the edge cases you can see. Clean up what you touched. If something is broken adjacent to your change, flag it. But don't invent new scope — there's a difference between thoroughness and gold-plating.
- **Agent-native by default** - Design so agents can achieve any outcome users can. Tools are atomic primitives; features are outcomes described in prompts. Prefer file-based state for transparency and portability. When adding UI capability, ask: can an agent achieve this outcome too?

## Code Quality

### Hard limits

1. ≤100 lines/function, cyclomatic complexity ≤8
2. ≤5 positional params
3. 100-char line length
4. Absolute imports only — no relative (`..`) paths
5. Google-style docstrings on non-trivial public APIs

### Zero warnings policy

Fix every warning from every tool — linters, type checkers, compilers, tests. If a warning truly can't be fixed, add an inline ignore with a justification comment. Never leave warnings unaddressed; a clean output is the baseline, not the goal.

### Comments

Code should be self-documenting. No commented-out code—delete it. If you need a comment to explain WHAT the code does, refactor the code instead.

### Error handling

- Fail fast with clear, actionable messages
- Never swallow exceptions silently
- Include context (what operation, what input, suggested fix)

### Reviewing code

Evaluate in order: architecture → code quality → tests → performance. Before reviewing, sync to latest remote (`git fetch origin`).

For each issue: describe concretely with file:line references, present options with tradeoffs when the fix isn't obvious, recommend one, and ask before proceeding.

### Testing

**Test behavior, not implementation.** Tests should verify what code does, not how. If a refactor breaks your tests but not your code, the tests were wrong.

**Test edges and errors, not just the happy path.** Empty inputs, boundaries, malformed data, missing files, network failures — bugs live in edges. Every error path the code handles should have a test that triggers it.

**Mock boundaries, not logic.** Only mock things that are slow (network, filesystem), non-deterministic (time, randomness), or external services you don't control.

**Verify tests catch failures.** Break the code, confirm the test fails, then fix. Use mutation testing (`cargo-mutants`, `mutmut`) for verify systematically. Use property-based testing (`proptest`, `hypothesis`) for parsers, serialization, and algorithms.

## Development

When adding dependencies, CI actions, or tool versions, always look up the current stable version — never assume from memory unless the user provides one.

### Apple platform artifacts

For Apple iOS/macOS research and tooling (`ipsw`, DSC/dyld_shared_cache work,
kernelcache/KC analysis, extracted firmware), start artifact discovery in the
directory named by the `$APPLE_FIRMWARE_DIR` environment variable (resolve it
with `echo $APPLE_FIRMWARE_DIR`; it currently points at `~/Apple`). Do not scan
the whole filesystem looking for IPSWs, extracted DSCs, or kernelcaches; search
that directory first and ask before widening the search.

### Shared build caches

Every agent and session on this host shares one Go build cache, one Go module
cache and one Rust compiler cache (`kache`, set as `rustc-wrapper` in
`~/.cargo/config.toml`). They are tens of gigabytes; a private copy per session
wastes the SSD and throws away every cache hit.

- Build with the defaults. Never set `GOCACHE`, `GOMODCACHE`, `GOPATH`,
  `GOFLAGS=-modcacherw`, `CARGO_HOME`, `RUSTC_WRAPPER` or `KACHE_CACHE_DIR`, and
  never point `CARGO_TARGET_DIR` or `--target-dir` at a temp directory.
- The sandbox already allows writes to these caches. If a build cannot write to
  one, or cannot download a dependency, stop and report the denied path or host.
  Do not work around it with a private cache.
- Do not run `go clean -cache`, `go clean -modcache` or clear the `kache` cache.
- A worktree gets its own `target/`; that is expected, and `kache` makes it cheap.

### Host Defaults

- User-facing terminal examples should assume macOS with Homebrew and Fish unless the target is explicitly Linux, a container, or a remote host.
- Use Fish-compatible syntax for copy/paste snippets. Prefer `env NAME=value command` for one-shot environment variables.
- Prefer macOS-native tools in examples: `brew`, `open`, `pbcopy`/`pbpaste`, `security`, and `xcode-select`. Avoid `apt`, `yum`, `systemctl`, `xdg-open`, or Linux clipboard tools unless the target environment requires them.
- Homebrew is available under the Apple Silicon prefix when an absolute path is necessary; prefer `brew --prefix` in reusable commands.

### CLI tools

| tool | replaces | usage |
|------|----------|-------|
| `rg` (ripgrep) | grep | `rg "pattern"` - 10x faster regex search |
| `fd` | find | `fd "*.py"` - fast file finder |
| `ast-grep` | - | `ast-grep --pattern '$FUNC($$$)' --lang py` - AST-based code search |
| `shellcheck` | - | `shellcheck script.sh` - shell script linter |
| `shfmt` | - | `shfmt -i 2 -w script.sh` - shell formatter |
| `actionlint` | - | `actionlint .github/workflows/` - GitHub Actions linter |
| `zizmor` | - | `zizmor .github/workflows/` - Actions security audit |
| `prek` | pre-commit | `prek run` - fast git hooks (Rust, no Python) |
| `wt` | git worktree | `wt switch branch` - manage parallel worktrees |
| `trash` | rm | `trash file` - moves to macOS Trash (recoverable). **Never use `rm -rf`** |

Prefer `ast-grep` over ripgrep when searching for code structure (function calls, class definitions, imports, pattern matching across arguments). Use ripgrep for literal strings and log messages.

## Language Guidance

### Python

- **Python repos standard**. We use `uv` and `pyproject.toml` in all Python repos. Prefer `uv sync` for env and dependency resolution. Do not introduce `pip` venvs, Poetry, or `requirements.txt` unless asked.

**Runtime:** 3.13 with `uv venv`

| purpose | tool |
|---------|------|
| deps & venv | `uv` |
| lint & format | `ruff check` · `ruff format` |
| static types | `ty check` |
| tests | `pytest -q` |

**Always use uv, ruff, and ty** over pip/poetry, black/pylint/flake8, and mypy/pyright — they're faster and stricter. Configure `ty` strictness via `[tool.ty.rules]` in pyproject.toml. Use `uv_build` for pure Python, `hatchling` for extensions.

Tests in `tests/` directory mirroring package structure. Supply chain: `pip-audit` before deploying, pin exact versions (`==` not `>=`), verify hashes with `uv pip install --require-hashes`.

### TypeScript

- In TypeScript codebases NEVER, EVER use `any` we are better than that. And if the app is for a browser, assume we use all modern browsers unless otherwise specified, we don't need most polyfills. Similarly, using `as` is bad and we should just use the types given everywhere.

**Runtime:** Node 22 LTS, ESM only (`"type": "module"`)

| purpose | tool |
|---------|------|
| lint | `oxlint` |
| format | `oxfmt` |
| test | `vitest` |
| types | `tsc --noEmit` |

**Always use oxlint and oxfmt** over eslint/prettier — they're faster and stricter. Enable `typescript`, `import`, `unicorn` plugins.

**tsconfig.json strictness** — enable all of these:
```jsonc
"strict": true,
"noUncheckedIndexedAccess": true,
"exactOptionalPropertyTypes": true,
"noImplicitOverride": true,
"noPropertyAccessFromIndexSignature": true,
"verbatimModuleSyntax": true,
"isolatedModules": true
```

Colocated `*.test.ts` files. Supply chain: `pnpm audit --audit-level=moderate` before installing, pin exact versions (no `^` or `~`), enforce 24-hour publish delay (`pnpm config set minimumReleaseAge 1440`), block postinstall scripts (`pnpm config set ignore-scripts true`).

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
   for unsafe code; fuzz/property tests for parsers and untrusted inputs. Test a
   built binary in a subprocess when panic-strategy behavior matters because the
   Rust test harness does not honor `panic = "abort"`.

**Runtime:** Repository-pinned toolchain/MSRV; otherwise current stable via `rustup`

| purpose | tool |
|---------|------|
| build & deps | `cargo` |
| lint | `cargo clippy --workspace --all-targets --all-features -- -D warnings` |
| format | `cargo fmt` |
| test | `cargo test` |
| release behavior | `cargo test --release` (for affected high-risk paths) |
| supply chain | `cargo deny check`; `cargo vet` when the repo is configured for it |
| safety check | `cargo careful test` (stdlib debug assertions + UB checks) |
| unsafe/FFI | `cargo +nightly miri test` (targeted supported tests) |

**Style:**
- Use iterator chains for clear transformations and `for` loops when mutation,
  side effects, early exits, or error handling are clearer
- Shadow variables through transformations (no `raw_x`/`parsed_x` prefixes)
- No wildcard matches; avoid `matches!` macro—explicit destructuring catches field changes
- Use `let...else` for early returns; keep happy path unindented

**Type design:**
- Newtypes over primitives (`UserId(u64)` not `u64`)
- Enums for state machines, not boolean flags
- `thiserror` for libraries, `anyhow` for applications
- `tracing` for logging (`error!`/`warn!`/`info!`/`debug!`), not println

**Optimization:**
- Write efficient code by default — correct algorithm, appropriate data structures, no unnecessary allocations
- Profile before micro-optimizing; measure after

**Failure model and production hardening:**
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
- Bound external inputs, allocation sizes, recursion depth, concurrency, queues,
  caches, connection pools, and retries. Put timeouts on external I/O.
- Long-running services must define graceful shutdown, readiness versus
  liveness, backpressure, and dependency-failure behavior.
- Keep `unsafe` blocks small. Document each with a `// SAFETY:` argument covering
  validity, aliasing, lifetimes, alignment, thread safety, and FFI ownership or
  unwind contracts as applicable.
- For deployment changes, prefer reproducible locked builds, least privilege,
  and minimal runtime artifacts. musl, alternative allocators/linkers,
  sandboxing, LTO, and `target-cpu=native` require target-specific evidence and
  are not universal defaults.

**Cargo.toml lints:**
```toml
[lints.rust]
unsafe_op_in_unsafe_fn = "deny"

[lints.clippy]
pedantic = { level = "warn", priority = -1 }
# Panic prevention
unwrap_used = "deny"
expect_used = "warn"
panic = "deny"
panic_in_result_fn = "deny"
unimplemented = "deny"
# No cheating
allow_attributes = "deny"
# Code hygiene
dbg_macro = "deny"
todo = "deny"
print_stdout = "deny"
print_stderr = "deny"
# Safety
await_holding_lock = "deny"
large_futures = "deny"
exit = "deny"
mem_forget = "deny"
# Pedantic relaxations (too noisy)
module_name_repetitions = "allow"
similar_names = "allow"
```

### Bash

All scripts must start with `set -euo pipefail`. Lint: `shellcheck script.sh && shfmt -d script.sh`

### Shell Examples

The user's interactive shell is Fish. When giving commands for the user to copy/paste into their terminal, prefer Fish-compatible syntax:

- Use `set -gx NAME value` for exported variables, or `env NAME=value command` for one command.
- Use Fish command substitution: `(command)`, not `$(command)`.
- Avoid Bash-only snippets in interactive examples: `export NAME=value`, `VAR=value command`, `source venv/bin/activate`, arrays, heredocs, and `for x in ...; do ...; done`.
- If a snippet is specifically a script file, use Bash/sh with a shebang and say to run it as `bash script.sh` or `sh script.sh`.
- Agent-executed commands may still use the harness shell; this guidance is for user-facing copy/paste examples.

### GitHub Actions

Pin actions to SHA hashes with version comments: `actions/checkout@<full-sha>  # vX.Y.Z` (use `persist-credentials: false`). Scan workflows with `zizmor` before committing. Configure Dependabot with 7-day cooldowns and grouped updates.

## Dependencies & External APIs

- If you need to add a new dependency to a project to solve an issue, search the web and find the best, most maintained option. Something most other folks use with the best exposed API. We don't want to be in a situation where we are using an unmaintained dependency, that no one else relies on.

## Workflow

**Before committing:**
1. Re-read your changes for unnecessary complexity, redundant code, and unclear naming
2. Run relevant tests — not the full suite
3. Run linters and type checker — fix everything before committing

**Commits:**
- Imperative mood, ≤72 char subject line, one logical change per commit
- Never amend/rebase commits already pushed to shared branches
- Never push directly to main — use feature branches and PRs
- Never commit secrets, API keys, or credentials — use `.env` files (gitignored) and environment variables

**Hooks and worktrees:**
- Install prek in every repo (`prek install`). Run `prek run` before committing. Configure auto-updates: `prek auto-update --cooldown-days 7`
- Parallel subagents require worktrees. Each subagent MUST work in its own worktree (`wt switch <branch>`), not the main repo. Never share working directories.

**Pull requests:**
Describe what the code does now — not discarded approaches, prior iterations, or alternatives. Only describe what's in the diff.

Use plain, factual language. A bug fix is a bug fix, not a "critical stability improvement." Avoid: critical, crucial, essential, significant, comprehensive, robust, elegant.

## Final Handoff

Before finishing a task:

1. Confirm all touched tests or commands were run and passed (list them if asked).
1. Summarize changes with file and line references.
1. Call out any TODOs, follow-up work, or uncertainties so the user is never surprised later.
