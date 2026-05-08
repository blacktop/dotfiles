---
name: go-performance
description: Measure and improve Go program performance on modern Go (1.24+). Use when profiling Go code, diagnosing CPU or memory bottlenecks, investigating latency or contention, writing or fixing benchmarks, comparing benchmark results, using pprof or trace data, applying PGO, or tuning hot-path Go code.
---

# Go Performance

Start with measurement, not rewriting.

## When NOT to use this skill

- No measurement of an actual performance problem exists yet. Write the benchmark or capture the profile first; do not optimize speculatively.
- The task is correctness, refactoring, or API design without a throughput, latency, or resource concern.
- The user wants a Go language tutorial or general code review, not performance work.

## Read the right reference

- Read [references/measurement.md](references/measurement.md) for benchmark setup, `go test` flags, `pprof`, trace, flight recording, runtime metrics, and PGO workflow.
- Read [references/optimization.md](references/optimization.md) when changing code after measurement or reviewing hot-path code.
- Read [references/hot-path.md](references/hot-path.md) only after profiling names a single dominant CPU kernel: covers inlining cost budget, dispatch cost (generics/interface/closure), bounds-check-elimination hints, register-pressure diagnosis, and assembly/SIMD escalation.

## Default workflow

1. Reproduce the problem and name the metric that matters: `ns/op`, `B/op`, `allocs/op`, throughput, tail latency, pause time, goroutine growth, or CPU saturation.
2. Add or repair a benchmark before changing code. On Go 1.24+ prefer `b.Loop()` for new or edited benchmarks unless the repo must support older Go.
3. Run the benchmark repeatedly and compare with `benchstat`; do not trust one run.
4. Collect one diagnostic at a time: CPU, heap/allocs, mutex, block, or trace. Do not mix profiles unless you must; diagnostics can distort each other.
5. Fix the dominant cost first: algorithmic complexity, redundant work, bad data layout, excess allocation, or contention.
6. Re-run the same benchmark and compare with `benchstat`.
7. Apply PGO only after the code path is correct and the profile is representative.
8. Validate the change under realistic service conditions with runtime metrics, `net/http/pprof`, or flight recording if the issue is production-only.

## Rules of engagement

- Prefer algorithmic or architectural fixes over stylistic micro-optimizations.
- Use benchmark evidence and profiles to justify code complexity.
- For long-running services, profile the service shape you actually run; microbenchmarks alone are not enough.
- Use `-run='^$'` for benchmark-only runs.
- For contention or scheduler issues, use trace, block, and mutex tooling instead of only CPU profiles.
- For intermittent production latency, consider the Go 1.25+ flight recorder before building custom tracing machinery.

## Go 1.26-specific posture

- Re-measure old workarounds on Go 1.26; runtime and compiler changes may have made older allocation, cgo, and GC workarounds obsolete.
- On Linux containers, remember that Go 1.25+ made `GOMAXPROCS` container-aware by default. Do not cargo-cult `automaxprocs` into modern Go services without a measured reason.
- Use `testing.T.ArtifactDir` plus `go test -artifacts -outputdir ...` when a benchmark or perf regression test needs to retain profiles, traces, or other debugging output.

## Output expectations

When reporting findings or a fix:

1. State the bottleneck and the evidence.
2. State the specific change and why it should move the measured metric.
3. Report before/after benchmark or profile deltas.
4. Call out residual risks, version assumptions, or production-only gaps.
