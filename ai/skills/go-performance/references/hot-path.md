# CPU-Bound Hot-Path Techniques

Source: distilled from "Notes from optimizing CPU-bound Go hot paths" (blog.andr2i.com, 2026-05-03) plus current Go 1.26 compiler behavior.

Read this only after measurement has named a single hot kernel that dominates CPU time. These techniques trade source-code clarity for cycles; do not apply them speculatively.

## Inlining cost budget

The Go compiler inlines functions whose internal "cost" stays under approximately 80 units. Once inlined, the call disappears and the body becomes part of the caller's optimization problem (better register allocation, more BCE, more constant propagation).

To check whether a function is being inlined:

```bash
go build -gcflags=all='-m=2' ./pkg 2>&1 | rg 'can inline|inlining call|cannot inline'
```

If the hot function is just over budget, reduce its cost rather than rewriting the algorithm:

- extract panic and error paths into separate functions marked `//go:noinline`
- collapse obvious redundancies and unused locals
- split rarely taken branches out of the hot loop

PGO raises the inlining threshold per call site based on profile evidence. It is the right escape hatch for end-product binaries; library authors cannot rely on consumers running it.

## Dispatch cost: avoid abstractions in tight loops

Inside the inner loop of a CPU-bound kernel, abstractions that add an extra dispatch step are expensive. The blog measurement on a Brotli hash kernel (378 MiB/s baseline) shows the cost:

| Form                    | Throughput     | Delta     |
| ----------------------- | -------------- | --------- |
| Concrete function       | 378.0 MiB/s    | baseline  |
| Generic `[T any]`       | 320.6 MiB/s    | -15.18 %  |
| Closure (`func(...)`)   | 322.0 MiB/s    | -14.82 %  |
| Interface method        | 274.3 MiB/s    | -27.44 %  |

Why each costs more:

- **Generics**: Go uses GC Shape Stenciling, not full monomorphization. Method calls on a type parameter dispatch through a generics dictionary, and the inliner explicitly does not inline them even when the concrete type is statically known.
- **Closures**: captured variables force stack allocation; the function pointer must be loaded on every call, and the compiler cannot inline through it.
- **Interfaces**: itab indirection on every call, and devirtualization rarely fires in real codebases.

These deltas only matter when each call does little work (byte-oriented kernels, tight inner loops). Once the call body processes ~64 bytes of input or more per invocation, the dispatch overhead falls into low single digits as a fraction of total time.

### Specialization patterns

When measurement names a hot kernel and an abstraction is in the way:

1. Hand-duplicate the function for each concrete type or strategy.
2. If the duplicate count exceeds ~5 and the bodies stay synchronized, switch to `go generate` with text templates.
3. As a last resort, manually inline the callee into the caller (accept the maintenance cost).

The blog author kept 16 hand-duplicated variants because the bodies diverged during tuning, making templates harder to maintain than the duplication.

## Compiler-friendly idioms

These rewrites are mathematically transparent but communicate invariants to the compiler so it can drop guard instructions.

### Bounds Check Elimination (BCE) via hint loads

A single dummy access at the top of a loop proves the upper bound for all subsequent indexed accesses:

```go
// hint to compiler: indices 0..3 are valid below
_ = b[3]
v := uint32(b[0]) | uint32(b[1])<<8 | uint32(b[2])<<16 | uint32(b[3])<<24
```

Without the hint, each `b[i]` emits a `CMPQ` and conditional branch. After the hint, the compiler proves all four are in bounds and removes the per-access checks. See golang/go#14808 for the formal pattern.

### Shift masking

When the shift amount is provably less than the data width, mask it explicitly:

```go
// before: compiler emits SHLQ + CMPQ + SBBQ + ANDQ guard sequence
y := x << n

// after: collapses to a single SHLQ; mask is a no-op when n < 64
y := x << (n & 63)
```

The mask is identity for valid `n`, but it is the proof the compiler needs to drop the guard.

### Pointer arithmetic via `unsafe`

When the access pattern cannot be expressed as a hint load, `unsafe.Pointer` arithmetic skips bounds checks entirely. Treat as a last resort: write a Go fallback alongside, validate with race-free tests on representative inputs, and document the safety argument inline.

## Diagnose register pressure from assembly

When optimizing a tight loop, dump the assembly:

```bash
go test -gcflags='-S' -run='^$' -bench='^BenchmarkFoo$' ./pkg 2>&1 | rg -A 60 BenchmarkFoo
```

Look for repeated stack reloads inside the loop body, for example:

```
MOVQ 0x20(SP), AX
MOVQ 0x28(SP), BX
MOVQ 0x30(SP), CX
```

Many `MOVQ ... SP` per iteration mean the compiler has spilled live values to the stack because the loop exceeds available registers. Reduce live values: shorten variable lifetimes, hoist invariants, drop unused intermediates, or split the loop into two stages.

## Last-resort techniques

Apply these only after measurement, BCE, specialization, and inlining work have run out.

### Manual loop unrolling

Go has no `//go:unroll`. Manually duplicate loop bodies when the per-iteration overhead (increment, compare, branch) is a meaningful fraction of the work and the unrolled body still fits register and i-cache budgets. Verify with benchmarks; unrolling sometimes regresses due to i-cache or alignment effects.

### Whole-function assembly with Go fallback

For algorithms that need prefetch, hand-tuned SIMD, or precise register allocation, write the entire hot function in Plan 9 assembly:

- ship a portable `_amd64.s` (and `_arm64.s` if relevant) with a build tag
- keep a portable Go fallback for other platforms and for verification
- never write assembly for tiny helpers; they pay the call overhead without the inlining benefit

Go does not yet expose `PREFETCHT0` as an intrinsic to user code (proposal: golang/go#68769); whole-function assembly is the current workaround when prefetch matters.

### Experimental SIMD

On Go 1.26 with `GOEXPERIMENT=simd`, the experimental SIMD package exposes vector intrinsics on AMD64 (golang/go#73787). It is useful for portable vector kernels but expect API changes. Library code should keep an assembly or scalar fallback until the API stabilizes.

## Trust the measurement

Optimization deltas under ~3-5 % are usually code-layout noise (where the linker placed the function), not a real algorithmic win. Validate with the layout-noise procedure in [measurement.md](measurement.md#code-layout-noise) before claiming a small improvement.
