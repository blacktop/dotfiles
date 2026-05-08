# Optimization Heuristics

This file combines current Go 1.26-era practice with the strongest hot-path guidance from the `ipsw` `go-performance` skill.

For deep CPU-bound hot-path techniques (inlining cost budget, dispatch cost, BCE hints, assembly fallback), read [hot-path.md](hot-path.md) after profiling identifies a dominant kernel.

## Fix in this order

1. Eliminate unnecessary work.
2. Improve algorithmic complexity or batching.
3. Reduce allocations and copying.
4. Reduce lock contention or scheduler stalls.
5. Re-check whether PGO improves the already-good version.
6. Apply micro-optimizations only on measured hot paths.

## Go 1.26 reality check

Before preserving complex old workarounds, re-measure on Go 1.26:

- Green Tea GC is now on by default.
- baseline cgo overhead is lower.
- the compiler can place more slice backing stores on the stack.
- experimental SIMD package is available behind `GOEXPERIMENT=simd` on AMD64; see [hot-path.md](hot-path.md#experimental-simd) before adopting.

Practical effect:

- keep `sync.Pool`, manual reuse, and cgo batching only when benchmarks still justify them
- remove cargo-culted allocation avoidance if the current compiler/runtime already made it cheap

## Allocation and escape work

If profiles show allocation pressure:

- preallocate slices and maps when final size is known
- reduce temporary objects in inner loops
- inspect escape and inlining output when needed:

```bash
go test -gcflags=all=-m=2 ./pkg 2>&1 | rg 'escapes to heap|moved to heap|cannot inline'
```

Use compiler diagnostics to explain an allocation you already measured, not as a substitute for profiling.

## Hot-path patterns worth carrying forward

Use these only when the benchmark or profile points at them.

### Prefer `strconv` over `fmt` for primitive string conversion

```go
// slower
s := fmt.Sprint(n)

// faster
s := strconv.Itoa(n)
```

### Avoid repeated `string` to `[]byte` conversions in loops

```go
// slower
for b.Loop() {
    w.Write([]byte("hello"))
}

// faster
data := []byte("hello")
for b.Loop() {
    w.Write(data)
}
```

### Pre-size slices and maps

```go
items := make([]T, 0, n)
index := make(map[string]T, n)
```

### Pass small values directly

Do not pass pointers just to avoid copying a string or interface-sized value. The indirection can be more expensive and makes escape behavior worse.

Bad examples:

- `*string`
- `*io.Reader`

Keep pointer parameters when mutation, identity, or large-struct copying is the real requirement.

## Concurrency and contention

If CPU is low but latency is bad, suspect waiting rather than compute:

- inspect mutex and block profiles
- inspect trace for runnable goroutine buildup and scheduler delay
- benchmark parallel paths with `b.RunParallel` and `-cpu`

On Linux containers, do not assume `GOMAXPROCS` needs manual tuning first. Go 1.25+ already accounts for CPU quota by default. Measure before adding compatibility shims.

## Memory limit tuning

If the service fights memory pressure, use `GOMEMLIMIT` or `runtime/debug.SetMemoryLimit` deliberately and verify the effect with runtime metrics.

Be careful:

- a memory limit that is too low can force the GC to run almost continuously
- the Go memory limit does not include memory owned outside the Go runtime, such as C allocations or `syscall.Mmap`

## What good looks like

A solid optimization change usually has all of these:

- a benchmark or production metric that reproduces the problem
- a profile or trace that isolates the dominant cost
- a targeted code change with a simple explanation
- a `benchstat` comparison or production delta showing improvement
- no extra complexity that lacks measured payoff
