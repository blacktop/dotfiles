# Developer-tool telemetry defaults

`setup.sh` sources `env.sh` before its first installer/Homebrew call, then runs
`privacy/setup.sh` after the Brewfile installs Go. Standalone Rust and AI setup
also source the opt-outs. Fish loads `00-privacy.fish`; Claude and Codex templates
set the same values for agent children that do not inherit a Fish session.

Run `sh privacy/setup.sh` to apply just the host privacy settings. It invokes
supported commands, verifies Go reports `off`, and links the Fish defaults.
It does not install tools or read/delete collected telemetry records.

| Tool | Default |
| --- | --- |
| Go, gopls, govulncheck and other Go-telemetry participants | `go telemetry off`; disables collection and upload. `local` is insufficient. The opt-out itself requires writing the mode configuration file. |
| Homebrew | `HOMEBREW_NO_ANALYTICS=1` before setup's first call, plus persistent `brew analytics off` |
| kache | `KACHE_RECORD_SESSIONS=0` disables automatic optional session/GC telemetry recording; does not disable compilation caching |
| Semgrep | `SEMGREP_SEND_METRICS=off` |
| Tools supporting common opt-outs | `DO_NOT_TRACK=1`, `DISABLE_TELEMETRY=1`, `DISABLE_ERROR_REPORTING=1` |
| Claude | Telemetry/error reporting disabled in its settings environment |
| Codex | Analytics/feedback disabled and OpenTelemetry exporters set to `none` |
| VS Code / Zed | Existing source settings disable telemetry; Zed also disables diagnostic reporting |

No `GOTELEMETRY=off` assignment: that variable reports Go's mode and is not its
configuration mechanism. No obsolete `rustup telemetry disable` command: rustup
removed that historical feature. Rustup's optional developer OpenTelemetry
instrumentation requires a custom build feature; this setup does not enable it.
No unsupported Cargo/rustc opt-out flags are invented.

These are defaults for the listed tools, not a universal enforcement mechanism.
Explicit command flags or custom configurations can override some tools' defaults
(for example, kache `--record` or `ignore_env`). Ordinary build-cache metadata,
application diagnostics, and local agent session/status files are separate from
these opt-in telemetry collectors and are not removed. Existing long-running
language servers and agents should be restarted to pick up the new settings.

Sources: [Go telemetry](https://go.dev/doc/telemetry),
[Homebrew analytics](https://docs.brew.sh/Analytics),
[Semgrep metrics](https://docs.semgrep.dev/metrics),
[kache 0.26.3 recording setting](https://github.com/kunobi-ninja/kache/blob/v0.26.3/src/config.rs),
[rustup telemetry removal](https://github.com/rust-lang/rustup/issues/341),
[rustup developer tracing](https://rust-lang.github.io/rustup/dev-guide/tracing.html).
