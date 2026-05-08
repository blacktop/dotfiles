# Measurement Workflow

Source snapshot: refreshed 2026-03-12 from official Go 1.26 docs and blog posts

- Go 1.26 release notes: https://go.dev/doc/go1.26
- Diagnostics overview: https://go.dev/doc/diagnostics
- `testing.B.Loop`: https://go.dev/blog/testing-b-loop
- `runtime/pprof`: https://pkg.go.dev/runtime/pprof
- `net/http/pprof`: https://pkg.go.dev/net/http/pprof
- `runtime/trace` and flight recorder: https://pkg.go.dev/runtime/trace and https://go.dev/blog/flight-recorder
- PGO: https://go.dev/doc/pgo
- `benchstat`: https://pkg.go.dev/golang.org/x/perf/cmd/benchstat

## Benchmark first

Prefer a targeted benchmark before changing code.

For new or updated benchmarks on Go 1.24+:

```go
func BenchmarkFoo(b *testing.B) {
    fixture := newFixture()
    for b.Loop() {
        foo(fixture)
    }
}
```

Why `b.Loop`:

- excludes setup and cleanup from timing
- avoids most manual timer management
- helps prevent dead-code elimination surprises

Use `b.RunParallel` for concurrent code paths and pair it with `go test -cpu`.

## Standard benchmark commands

Collect stable results before and after a change:

```bash
go test -run='^$' -bench='^BenchmarkFoo$' -benchmem -count=10 ./pkg > before.txt
go test -run='^$' -bench='^BenchmarkFoo$' -benchmem -count=10 ./pkg > after.txt
benchstat before.txt after.txt
```

Useful variations:

```bash
go test -run='^$' -bench='^BenchmarkFoo$' -benchmem -benchtime=500ms ./pkg
go test -run='^$' -bench='^BenchmarkFoo$' -benchmem -benchtime=100x ./pkg
go test -run='^$' -bench='^BenchmarkParallelFoo$' -benchmem -cpu=1,2,4 ./pkg
```

Rules:

- Use `-count=10` or more before trusting `benchstat`.
- Use `-benchmem` for almost every optimization pass.
- Do not mix `-race`, coverage, or unrelated noisy tests into performance measurement runs.

### Code-layout noise

Where the linker places a function in the binary affects its alignment to cache lines and decode windows, which can shift benchmark results by 3-4 % even when nothing about the function changed. Treat single-commit deltas under ~3-5 % as noise unless the result reproduces across an unrelated change.

To estimate the inherent layout variance of a benchmark:

1. Run the benchmark 10 times and record the result.
2. Add or remove a tiny unrelated function elsewhere in the binary (a no-op exported helper works).
3. Run the benchmark 10 times again.
4. The spread between the two `benchstat` outputs is the layout-noise floor; real wins must clear it.

Run benchmarks longer than feels necessary, especially for small kernels.

Install `benchstat` if needed:

```bash
go install golang.org/x/perf/cmd/benchstat@latest
```

## Profile one dimension at a time

The Go docs explicitly warn that diagnostics can interfere with each other. Collect focused data.

### CPU

```bash
go test -run='^$' -bench='^BenchmarkFoo$' -cpuprofile=cpu.pprof ./pkg
go tool pprof -top -cum cpu.pprof
go tool pprof -http=:0 cpu.pprof
```

### Heap and allocs

```bash
go test -run='^$' -bench='^BenchmarkFoo$' -memprofile=mem.pprof ./pkg
go tool pprof -top -sample_index=alloc_space mem.pprof
go tool pprof -top -sample_index=alloc_objects mem.pprof
```

Use `-memprofilerate=1` only when you need more precise allocation data and can tolerate the extra overhead.

### Mutex and block contention

```bash
go test -run='^$' -bench='^BenchmarkFoo$' -mutexprofile=mutex.pprof -mutexprofilefraction=1 ./pkg
go test -run='^$' -bench='^BenchmarkFoo$' -blockprofile=block.pprof ./pkg
go tool pprof -top mutex.pprof
go tool pprof -top block.pprof
```

### Trace

Use trace for scheduler, latency, blocking, and concurrency-path issues:

```bash
go test -run='^$' -bench='^BenchmarkFoo$' -trace=trace.out ./pkg
go tool trace trace.out
```

## Service profiling

For a long-running service, prefer `net/http/pprof` or `runtime/pprof`.

```go
import _ "net/http/pprof"
```

```bash
go tool pprof 'http://localhost:6060/debug/pprof/profile?seconds=30'
go tool pprof http://localhost:6060/debug/pprof/heap
curl -o trace.out 'http://localhost:6060/debug/pprof/trace?seconds=5'
go tool trace trace.out
```

Notes:

- `net/http/pprof` endpoints must be requested with `GET`.
- heap, allocs, mutex, block, and goroutine endpoints support `seconds=N` delta profiles.
- CPU and trace endpoints use `seconds=N` as capture duration.

## Flight recorder

Use the Go 1.25+ flight recorder when latency incidents are intermittent and you need the last few seconds before failure rather than a constantly running full trace.

It is a better fit than ad hoc tracing when:

- the service is long-running
- the trigger is rare or unpredictable
- you need scheduler and goroutine context just before the incident

## Runtime metrics

Use `runtime/metrics` for low-overhead continuous observation in production.

High-signal keys:

- `/gc/heap/live:bytes`
- `/gc/heap/goal:bytes`
- `/gc/gomemlimit:bytes`
- `/cpu/classes/gc/total:cpu-seconds`
- `/sched/goroutines:goroutines`
- `/sched/latencies:seconds`
- `/sync/mutex/wait/total:seconds`
- `/cgo/go-to-c-calls:calls`

Use these to validate that a benchmark win also improves the live system shape.

## PGO

Go PGO consumes representative CPU pprof profiles.

Typical workflow:

```bash
curl -o cpu.pprof 'http://localhost:6060/debug/pprof/profile?seconds=30'
go build -pgo=cpu.pprof ./cmd/server
```

Or place a representative profile at `default.pgo` in the main package directory and let `go build` pick it up automatically.

Rules:

- use representative production traffic when possible
- use benchmark-generated profiles only when they are truly representative
- do not expect PGO to rescue bad algorithms or contention bugs
- re-run benchmarks after enabling PGO; keep it only if it helps your workload

## Artifact handling in tests

If a test or benchmark emits traces, profiles, or logs for later inspection, use `t.ArtifactDir()` or `b.ArtifactDir()` and run:

```bash
go test -artifacts -outputdir "$PWD/test-output" ./...
```

This keeps performance evidence attached to the failing or interesting test instead of scattering files across the repo.
