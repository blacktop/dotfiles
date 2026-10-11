# Rust and Go development paths on macOS

Audited 2026-09-26 using Exa discovery, upstream documentation and source.
Host versions checked: Rust/Cargo 1.98.1, Go 1.27.1, kache 0.26.3.
Defaults below assume the host's existing shared caches, without redirecting any
environment variables. Repository configuration, custom tools and build scripts
can introduce other paths; this is a defined tool inventory, not a claim that
every program can write only here.

`dev-cache-paths.json` lists the shared writable paths and kache socket. The
regression check requires both agent templates to cover that inventory. Codex's
`gcloud` permission profile inherits these filesystem grants from `dev`.

## Ordinary builds, analysis and tool state

Directory grants include their descendants, temporary files, locks and renames.
File grants under Cargo home are intentionally individual files.

| Tool/workflow | Default writable paths | What they contain |
| --- | --- | --- |
| Cargo fetch/build/check/test/clippy/doc | `~/.cargo/registry/`, `~/.cargo/git/` | Registry indexes, crate archives, extracted sources, bare Git dependencies and checkouts |
| Cargo coordination | `~/.cargo/.package-cache`, `~/.cargo/.package-cache-mutate` | Cross-process cache locks |
| Cargo cache tracking | `~/.cargo/.global-cache`, `~/.cargo/.global-cache-journal` | SQLite last-use database and rollback journal; no evidence in the inspected source requires WAL/SHM siblings |
| rustup toolchains/components/targets | `~/.rustup/` | Toolchains, downloads, extraction temp files, update hashes and rustup state; covers automatic installation of a pinned toolchain |
| kache | `~/Library/Caches/kache/` | Artifact store, SQLite index, locks, logs, probe/compiler metadata, scheduler and build-session state |
| kache daemon | `~/Library/Caches/kache/daemon.sock` | Unix-socket permission in addition to directory writes; clients connect to the launchd-managed daemon |
| Go build/test/vet/run, fuzzing | `~/Library/Caches/go-build/` | Build/test artifacts and cached fuzz inputs |
| Go module downloads and automatic toolchains | `~/go/pkg/mod/` | Downloads, lock files, VCS cache, extracted modules, and `golang.org/toolchain` downloads |
| Go checksum database | `~/go/pkg/sumdb/` | Downloaded checksum-database state; module-cache descendants also contain related download data |
| golangci-lint | `~/Library/Caches/golangci-lint/` | Linter cache, in addition to Go's caches |
| Staticcheck | `~/Library/Caches/staticcheck/` | Analysis cache, in addition to Go's caches |
| gopls | `~/Library/Caches/gopls/` | Persistent analysis/index cache |

Sources: [Cargo home](https://doc.rust-lang.org/cargo/guide/cargo-home.html),
[Cargo locks](https://github.com/rust-lang/cargo/blob/master/src/cargo/util/cache_lock.rs),
[Cargo tracking database](https://github.com/rust-lang/cargo/blob/master/src/cargo/core/global_cache_tracker.rs),
[rustup home](https://rust-lang.github.io/rustup/devel/environment-variables.html),
[kache configuration](https://ninja.kunobi.com/docs/kache/getting-started/configuration),
[kache 0.26.3 path implementation](https://github.com/kunobi-ninja/kache/blob/v0.26.3/src/config.rs),
[Go build cache](https://go.dev/src/cmd/go/internal/cache/default.go),
[GOPATH uses](https://go.dev/wiki/GOPATH),
[Go toolchain downloads](https://go.dev/doc/toolchain),
[golangci-lint cache](https://golangci-lint.run/docs/configuration/cli/#cache),
[Staticcheck cache](https://github.com/dominikh/go-tools/blob/master/lintcmd/cache/default.go),
[gopls cache](https://github.com/golang/tools/blob/master/gopls/internal/filecache/filecache.go),
[Go telemetry](https://go.dev/doc/telemetry),
[gopls prompt state](https://github.com/golang/tools/blob/master/gopls/internal/server/prompt.go).
Go's [OS path helpers](https://pkg.go.dev/os#UserConfigDir) map user configuration
to `Library/Application Support` and caches to `Library/Caches` on macOS.

Telemetry is excluded from the writable inventory. Dotfiles
[privacy setup](../privacy/README.md) makes the opt-out persistent. Run `go telemetry off` to
disable both local collection and uploading for Go telemetry participants,
including gopls and govulncheck. This writes the opt-out configuration, not a
telemetry report. `go telemetry` should then print `off`; `local` still collects
data and is not the desired setting. Restart long-running Go tools after changing
the mode. Do not substitute `GOTELEMETRY=off`: Go documents that variable as a
read-only report of the mode, not the configuration mechanism.
Neither `~/Library/Application Support/go/telemetry/` nor
`~/Library/Application Support/gopls/prompt/` gets a sandbox write allowance.
Existing telemetry records are not inspected or deleted by this change.

The cache root is enough for kache's current file layout; do not enumerate each
SQLite sidecar or cache entry. Its default runtime directory is the cache root.
Custom runtime directories, volume stores or filesystem remotes need their own
actual paths. The host setup uses `kache init --yes`, which runs the daemon as a
launchd login service outside agent sandboxes. Without a running daemon, a kache
CLI command such as `kache stats` starts one that inherits the caller's sandbox;
Codex allows binding `daemon.sock`, so that daemon then fails to clean other
worktrees. Local caching itself does not require the daemon.

## Additional Rust checks

| Tool | Writable paths | Notes |
| --- | --- | --- |
| cargo audit | `~/.cargo/advisory-db/`, `~/.cargo/advisory-db..lock` | The double dot is intentional: current RustSec source uses `with_extension(".lock")` on `advisory-db`. Custom DB paths also move this sibling lock. |
| cargo deny | `~/.cargo/advisory-dbs/` | Separate plural directory containing advisory databases |
| cargo vet | `~/Library/Caches/cargo-vet/` | Cached crate/API/diff information; project `supply-chain/` records are workspace writes |
| Miri | `~/Library/Caches/org.rust-lang.miri/` | Generated Miri sysroot; project outputs remain under `target/miri/`; rust-src/Miri components are under rustup |
| nextest | `~/.local/state/nextest/`, `~/.cache/nextest/` | Current upstream source uses the XDG state location on macOS; published design docs describe the cache location. Both narrow roots are covered for version compatibility. |

Sources: [RustSec database and lock](https://github.com/RustSec/rustsec/blob/main/rustsec/src/repository/git/repository.rs),
[cargo-deny DB configuration](https://embarkstudios.github.io/cargo-deny/checks/advisories/cfg.html),
[cargo-vet cache selection](https://github.com/mozilla/cargo-vet/blob/main/src/main.rs),
[Miri sysroot selection](https://github.com/rust-lang/miri/blob/master/cargo-miri/src/util.rs),
[macOS ProjectDirs mapping](https://docs.rs/directories/latest/directories/struct.ProjectDirs.html#method.cache_dir),
[nextest current state location](https://github.com/nextest-rs/nextest/blob/main/nextest-runner/src/record/state_dir.rs),
[nextest published design](https://nexte.st/docs/design/architecture/recording-runs/).

## Workspace, temporary files and native tooling

- The assigned workspace must be writable: Cargo `target/` (including build-script
  `OUT_DIR`, packaging, docs, coverage and test outputs), Cargo.lock, Go module/work
  files, vendor/generated sources, Go fuzz regressions under `testdata/fuzz/`, and
  requested output files. Do not relocate a worktree's `target/` into a private
  scratch cache.
- Both `/tmp` (canonical `/private/tmp`) and the native per-user temporary directory
  must work. On macOS discover the latter with `getconf DARWIN_USER_TEMP_DIR` and
  canonicalize it; never hardcode its generated `/var/folders/.../T` component.
  Codex provides `:tmpdir`/`:slash_tmp`; Claude sync adds the native temp root.
- Clang, SDKs, linker and compiler installations normally need read/execute
  access, not write access. cgo, bindgen, C/C++ build dependencies and custom
  generators may use separately configured module caches or downloaded SDKs;
  add their actual tool-specific paths when configured, not all of `/Library`
  or `/opt/homebrew`.
- Local server/socket tests need network permissions too. A filesystem grant
  cannot grant Mach task ports for profiling, nor cancel Claude's built-in
  protection of paths such as `.vscode`. A crate unpack containing a protected
  directory may still need an authorized sandbox-exempt call.
- Git common/worktree metadata needs its resolved writable roots. Ignored private
  source and external path dependencies must actually exist in each worker's
  checkout or dependency setup; a cache grant cannot supply missing files.

See [Cargo build outputs](https://doc.rust-lang.org/cargo/reference/build-cache.html),
[Go fuzzing](https://go.dev/doc/security/fuzz/), and
[Claude sandbox behavior](https://code.claude.com/docs/en/sandboxing).

## Installation and configuration paths

These are distinct from running already-installed tools. They are inventoried
here but not added to the shared cache grants by this change.

| Operation | Additional destinations |
| --- | --- |
| `cargo install`, cargo-binstall, rustup self-update | `~/.cargo/bin/`; Cargo install tracking at `~/.cargo/.crates.toml` and `~/.cargo/.crates2.json`, plus installer temporary files |
| `go install` | `~/go/bin/` by default; existing GOBIN/GOPATH configuration can change it |
| Explicit versioned Go SDK download (`golang.org/dl`) | `~/sdk/go<VERSION>/`; separate from automatic module-based toolchain downloads |
| Global Cargo configuration | `~/.cargo/config.toml`; read for normal builds, write only when changing setup |
| kache setup | `~/.config/kache/config.toml`, Cargo configuration, optional `~/.local/lib/kache/shims/` and user service files; project `.kache.toml` belongs to the workspace |
| `go env -w` | `~/Library/Application Support/go/env` by default; this is persistent configuration, not a build-cache requirement |
| Homebrew install/upgrade | Homebrew installation prefix and its download/cache state; use the authorized package-install workflow |

Sources: [Cargo home/install tracking](https://doc.rust-lang.org/cargo/guide/cargo-home.html),
[Go install paths](https://go.dev/wiki/GOPATH),
[versioned Go installations](https://go.dev/doc/manage-install),
[Go environment configuration](https://pkg.go.dev/cmd/go#hdr-Environment_variables),
[kache setup](https://ninja.kunobi.com/kache).

Private registry/repository authentication is a separate capability, not a cache
directory. This inventory does not change credential-read restrictions, remote
push guards, destructive-operation guards, or the user's deployment/review holds.
It does not inspect shell startup files, dump environment variables, clear any
shared cache, or install tools. The opt-out command above explicitly disables
telemetry collection; granting build-cache access does not enable telemetry.
