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
strip = true         # strip symbols from final binary

[profile.profiling]
inherits = "release"
debug = true         # keep symbols for samply / perf
strip = false
```

Treat `lto = "fat"` and `codegen-units = 1` as experiments that slow builds; keep them when a benchmark shows the win. Add `panic = "abort"` only to a final binary whose failure model you have decided, never to a reusable library.

---

## 2. Source-level patterns for hot paths

These are the changes flamegraph analysis typically points to:

| Pattern | When | Example |
|---|---|---|
| **Pre-allocate** `Vec::with_capacity(n)` | hot loop showing `realloc`/`grow` in flamegraph | `Vec::with_capacity((total / capacity) + 1)` |
| **`SmallVec<[T; N]>`** | small collections (≤16 items typical) — avoids heap alloc until inline capacity is exceeded | `pub items: SmallVec<[usize; 8]>` |
| **`heapless::Vec<T, N>` / fixed-capacity buffers** | known upper bound, embedded/no_std-friendly paths, protocol fields with sane limits | reject out-of-policy inputs instead of allocating unboundedly |
| **`bytes::Bytes`** | network/parser buffers that need cheap clones or slices | slice shared input instead of cloning `Vec<u8>` |
| **`#[inline(always)]`** | tiny hot functions called in inner loops where call overhead dominates | `#[inline(always)] fn find_best_fit(...)` |
| **`#[cold]`** | error/slow paths so the optimizer pushes them out of the icache footprint | `#[cold] fn open_new_bin(...)` |
| **Early termination in propagation loops** | tree/graph updates where ancestors don't need touching once a value stabilises | `if self.tree[idx] == new_val { break; }` |
| **Avoid `clone()` in hot loops** | flamegraph shows `Drop` / `__rust_dealloc` near a loop body | reuse via `&mut`, swap with `mem::replace`, or use indices |

Apply one at a time, re-profile to confirm the win — don't shotgun.

### Allocation churn and fragmentation

When profiles show allocator frames or RSS grows under sustained throughput, decide whether the symptom is allocation CPU, allocator fragmentation, or both. A workload with thousands of short-lived DNS/HTTP/JSON-style objects per second can drive RSS upward without a Rust ownership leak.

Use this order:

1. **Reduce allocation count first.** Pre-size `Vec`/`HashMap`, reuse buffers, pass scratch buffers into hot functions, replace repeated `String`/`Vec` construction with borrowed views, and remove avoidable clones.
2. **Use bounded storage when the maximum is real.** For protocol fields, hashes, IDs, ALPN-like names, and embedded-friendly APIs, a fixed-capacity `heapless` buffer plus explicit rejection of abnormal sizes can be better than an unbounded heap allocation.
3. **Use shared byte buffers for parser/network data.** `bytes::Bytes` is useful when data arrives as a buffer and many decoded structures need owned, sliceable views without copying.
4. **Use inline-small collections for mostly-small data.** `SmallVec` can keep common cases off the heap but still spill for rare larger values. Avoid it when large inline capacity would bloat structs or stack frames.
5. **Try allocator swaps as evidence.** `jemalloc` or `mimalloc` can sharply reduce fragmentation/RSS on server workloads, but they are mitigation, not a substitute for reducing high-rate small allocations. Benchmark throughput, RSS, and latency for each allocator.

Do not blindly move everything to the stack. Stack allocation is cheap, but large inline buffers can inflate structs, increase copies, blow stack budgets, and hurt cache behavior. Pick the representation that matches the measured hot path and API constraints.

### Shrinking long-lived data (caches, indexes, tables)

A different memory problem from churn: millions of values that stay resident. RSS is roughly `bytes per entry × entries`, so each byte removed per entry scales with the entry count. samply won't show this. Measure per-entry footprint directly (see "Measuring per-entry footprint" in `reference.md`). (Reference: [Cloudflare 1.1.1.1 DNS cache](https://blog.cloudflare.com/dns-cache-memory-optimization-1111/). The layout changes below cut per-entry bytes 953→420, raised insert throughput 43%, and cut lookup latency 19%, because fewer allocations and better locality also make the cache faster.)

Apply in roughly this order, measuring after each:

| Change | When | Saves |
|---|---|---|
| **`Vec<T>` → `Box<[T]>`, `String` → `Box<str>`** | data is never modified after insertion | 8-byte capacity field per collection, plus unused spare capacity on the heap |
| **Merge sibling lists into one + small offsets** | several `Box<[T]>` fields always read together (e.g. answer/authority/additional sections) | each removed list's 16-byte ptr+len becomes a `u16`/`u32` offset |
| **Pack `bool` fields into a bitflags integer; reorder fields** | struct has several flags or small fields | the fields themselves plus the alignment padding around them, so the saving can exceed the fields' own size |
| **Drop fields derivable from context** | a value usually equals something the reader already holds (record owner == lookup key) | store `Option<Box<T>>` (`None` = "same as key") and rebuild the value at read time. That is 8 bytes for sized `T`, and 16 for `Box<str>`/`Box<[T]>`. The common case also skips a heap allocation |
| **Box large, rare enum variants** | enum is sized by its largest variant but most values are small variants (`A`/`AAAA` vs `NAPTR`) | common small variants stop paying for the largest one (144→24 bytes in the case study) |
| **Store variable records as one packed `Box<[u8]>`** | records are read sequentially and often copied straight to output | removes per-record enum and heap overhead. Contiguous bytes improve locality, and the output path can `memcpy` instead of re-serializing |

Costs to weigh:

- **Boxing adds an allocation per value.** The allocator rounds each request up to a size class (jemalloc: a 40-byte request uses a 48-byte bin), and every pointer to a separate allocation is a possible cache miss. Box only variants that are both large and rare.
- **Packed bytes give up random access.** Operations such as index-based rotation must walk the buffer. This is fine when per-entry counts are small.
- **Shrinking a `Vec` is not free.** `into_boxed_slice()` may reallocate, and the allocator may not reclaim the trimmed tail. For build-then-freeze data, serialize into a reusable scratch buffer, then allocate one exact-size `Box<[u8]>` and copy into it (`Box::from(&scratch[..])`). In the case study this raised insert throughput 13%.

Guard the win in code so a later field addition cannot silently undo it:

```rust
const _: () = assert!(std::mem::size_of::<CacheEntry>() <= 64);
const _: () = assert!(std::mem::size_of::<RecordData>() <= 24);
```

To see where the bytes go, print per-field sizes, padding, and variant sizes for one target. The output covers every type, so filter it:

```bash
cargo +nightly rustc --release --lib -- -Zprint-type-sizes 2>/dev/null \
    | rg -A12 'type: `(CacheEntry|RecordData)`'
```

Clippy's `large_enum_variant` lint only fires when variants differ by more than 200 bytes by default, so it misses a 144-byte enum like the case study's. Lower the threshold in `clippy.toml` to catch it:

```toml
enum-variant-size-threshold = 64
```

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
| Replacing `Vec` with `Box<[T]>` for speed | Marginal for CPU. The grow path is what `with_capacity` already fixes. It does pay off for *memory* when there are millions of long-lived, immutable values (see "Shrinking long-lived data"). |
| Custom global allocators (mimalloc, jemalloc) | Useful experiment for allocator fragmentation/RSS under churn, but high variance. Measure per-workload and still reduce hot allocation sites. |

---

## 6. Decision tree

```
symptom
   │
   ├─ RSS dominated by many long-lived values (cache/index), CPU profile cold?
   │     → Measure bytes/entry, then shrink layout (Box<[T]>, box rare variants, pack)
   │
   └─ samply shows hot function
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
