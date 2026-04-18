# Optimization (after profiling)

Once samply identifies hotspots, this is the toolkit for fixing them. Order of operations matters — flamegraph-driven source fixes beat compiler tools on already-optimized code.

> **Core principle**: profile first, optimize source, *then* reach for compiler tools. PGO can **regress** code that's already been hand-tuned because the recorded profile no longer matches hot paths. (Reference: [SeqPacker case study](https://alphakhaw.com/blog/seqpacker-profiling-rust-flamegraph-pgo-bolt) — manual fixes from flamegraph yielded 16.3% vs PGO's 15.2% on the same baseline, with PGO *regressing* the optimized code by ~1.2%.)

---

## 1. Cargo.toml release profile

```toml
[profile.release]
opt-level = 3
lto = "fat"          # cross-crate inlining + interprocedural opt — most impactful
codegen-units = 1    # serial LLVM pipeline → better codegen, slower compiles
panic = "abort"      # smaller binary, no unwind tables
strip = true         # strip symbols from final binary

[profile.profiling]
inherits = "release"
debug = true         # keep symbols for samply / perf
strip = false
```

`lto = "fat"` is the single highest-leverage knob. `codegen-units = 1` matters for tight inner loops.

---

## 2. Source-level patterns for hot paths

These are the changes flamegraph analysis typically points to:

| Pattern | When | Example |
|---|---|---|
| **Pre-allocate** `Vec::with_capacity(n)` | hot loop showing `realloc`/`grow` in flamegraph | `Vec::with_capacity((total / capacity) + 1)` |
| **`SmallVec<[T; N]>`** | small collections (≤16 items typical) — avoids heap alloc | `pub items: SmallVec<[usize; 8]>` |
| **`#[inline(always)]`** | tiny hot functions called in inner loops where call overhead dominates | `#[inline(always)] fn find_best_fit(...)` |
| **`#[cold]`** | error/slow paths so the optimizer pushes them out of the icache footprint | `#[cold] fn open_new_bin(...)` |
| **Early termination in propagation loops** | tree/graph updates where ancestors don't need touching once a value stabilises | `if self.tree[idx] == new_val { break; }` |
| **Avoid `clone()` in hot loops** | flamegraph shows `Drop` / `__rust_dealloc` near a loop body | reuse via `&mut`, swap with `mem::replace`, or use indices |

Apply one at a time, re-profile to confirm the win — don't shotgun.

---

## 3. PGO (Profile-Guided Optimization)

Use *after* source-level fixes, only if the profile still shows broad time across many warm functions (compiler can do better global decisions with workload data).

```bash
# 1. Instrumented build
RUSTFLAGS="-Cprofile-generate=$PWD/pgo-data" \
  cargo build --release

# 2. Run a representative workload (longer + more varied = better)
./target/release/binary <typical-args>

# 3. Merge raw profiles
llvm-profdata merge -o pgo-data/merged.profdata pgo-data/*.profraw

# 4. Rebuild using the profile
RUSTFLAGS="-Cprofile-use=$PWD/pgo-data/merged.profdata" \
  cargo build --release
```

**Caveats:**
- Stale profile data → silent regressions. Re-record after major source changes.
- Workload must mirror production input distribution; synthetic micro-benchmarks mislead.
- `llvm-profdata` ships with `rustup component add llvm-tools-preview`.

---

## 4. BOLT (Binary Optimization & Layout Tool, Linux only)

Reorders basic blocks and functions in the linked binary using runtime perf data.

```bash
# 1. Record cycles with perf (Linux only)
perf record -e cycles:u -o perf.data -- ./binary <args>

# 2. Convert to BOLT format
perf2bolt -p perf.data -o perf.fdata ./binary

# 3. Optimize binary
llvm-bolt ./binary -o binary.bolt \
    -data=perf.fdata \
    -reorder-blocks=ext-tsp \
    -reorder-functions=hfsort
```

**When BOLT helps:** large binaries with many cold paths (browsers, databases, compilers) where icache miss dominates.

**When it doesn't:** tight loops over small data already fitting in L1. SeqPacker's case showed 0% gain over PGO alone for integer arithmetic / tree traversal workloads.

---

## 5. What DOESN'T usually help

| Knob | Reality |
|---|---|
| `RUSTFLAGS="-C target-cpu=native"` | ~0% on scalar integer/pointer code; can **regress 5-8%** on already-optimized code due to AVX-512/AVX2 register pressure. Breaks portability — distribution wheels must use generic `x86_64`/`aarch64`. |
| Switching to nightly for `-Zthreads=N` | Compile-time only; runtime unchanged. |
| Replacing `Vec` with `Box<[T]>` | Marginal. The grow path is what `with_capacity` already fixes. |
| Custom global allocators (mimalloc, jemalloc) | High variance — sometimes wins, sometimes loses. Measure per-workload; don't cargo-cult. |

---

## 6. Decision tree

```
samply shows hot function
   │
   ├─ >5% of self time in alloc/dealloc?
   │     → Pre-allocate, SmallVec, or pool
   │
   ├─ Tight inner loop, small function called often?
   │     → #[inline(always)] (re-profile to verify)
   │
   ├─ Many warm functions, no single dominant hotspot?
   │     → Try PGO with realistic workload
   │
   ├─ Large binary, cold-path-heavy (parsers, CLIs with many subcommands)?
   │     → BOLT after PGO (Linux only)
   │
   └─ Already optimized, profile is "flat"?
         → Stop. Further wins need algorithmic changes, not micro-opt.
```

---

## 7. Benchmarking discipline

Don't trust a single run. Variance from background processes, CPU throttling, and ASLR can swamp small wins.

```bash
# Statistical rigor
cargo install cargo-criterion
cargo criterion

# Or for end-to-end timing across input sizes
hyperfine --warmup 3 --runs 20 \
    './target/release/binary small.input' \
    './target/release/binary large.input'
```

For PGO/BOLT comparisons, always benchmark *the same workload* the optimizer was trained on AND a held-out workload — divergence reveals overfitting.
