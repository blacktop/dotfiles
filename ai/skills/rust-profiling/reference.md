# Reference

## Prerequisites

### Install Samply

```bash
cargo install --locked samply
# OR
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/mstange/samply/releases/download/samply-v0.13.1/samply-installer.sh | sh
```

### Cargo.toml Profiling Profile

Add to your `Cargo.toml`:

```toml
[profile.profiling]
inherits = "release"
debug = true
strip = false
```

This gives:
- Release-level optimizations (accurate performance)
- Debug symbols (readable function names in profiler)
- Symbols kept even when `[profile.release]` sets `strip = true`

## Samply Commands

### `samply record`

Record a profile of command execution.

```bash
samply record [OPTIONS] <COMMAND> [ARGS...]
```

| Option | Description |
|--------|-------------|
| `--rate <HZ>` | Sampling rate in Hz (default: 1000) |
| `--save-only` | Don't open browser, just save profile |
| `-o <FILE>` | Output file path (default: profile.json) |
| `--iteration-count <N>` | Run command N times |
| `-p <PID>` | Attach to an existing process; on macOS run `samply setup` first |

### `samply load`

Open a previously saved profile.

```bash
samply load profile.json
```

### `samply setup` (macOS only)

Configure code signing for process attachment.

```bash
samply setup
```

## analyze_profile.py Options

```bash
python3 ~/.agents/skills/rust-profiling/scripts/analyze_profile.py [OPTIONS] <profile.json>
```

| Option | Description |
|--------|-------------|
| `--top, -n <N>` | Show top N functions (default: 20) |
| `--lib, -l <NAME>` | Filter to functions in library matching NAME |
| `--thread, -t <NAME>` | Filter to thread matching NAME |
| `--callers, -c <FUNC>` | Show callers of FUNC |
| `--callees <FUNC>` | Show callees of FUNC |
| `--tree` | Show call tree visualization |
| `--tree-depth <N>` | Max tree depth (default: 5) |
| `--min-pct <PCT>` | Minimum % threshold (default: 1.0) |
| `--json, -j` | Output as JSON |
| `--diff, -d <FILE>` | Compare against another profile |

## Troubleshooting

### "No symbols" or mangled names

1. Ensure `debug = true` in `[profile.profiling]`
2. Rebuild: `cargo build --profile profiling`
3. Verify binary has debug info: `file target/profiling/<binary>`

### Permission denied (macOS)

```bash
samply setup
```

### Very short runs show little data

- Increase sampling rate: `--rate 10000`
- Run operation in a loop
- Use `--iteration-count` to repeat command

### Profile is too large

- Lower sampling rate: `--rate 100`
- Profile shorter duration
- Filter to specific thread with `--thread`

### RSS grows but no leak is obvious

Treat rising RSS as a separate symptom from CPU time. A service that allocates and frees many small objects at high rate can look leaky even when ownership is correct; allocator fragmentation may leave unusable holes and drive RSS upward until it plateaus. Source: https://kerkour.com/rust-high-performance-memory-fragmentation-allocations.

Triage steps:

1. Confirm whether `malloc`, `free`, `realloc`, `alloc::alloc`, `__rust_alloc`, or `__rust_dealloc` appear in the profile. If they do, optimize allocation rate before tuning compiler flags.
2. Track RSS over a representative load window and compare it with request throughput or work units. A fragmentation signature often grows under churn and then stabilizes instead of growing without bound.
3. Run an allocator comparison as an experiment, not as proof of root cause. Try the system allocator, `jemallocator`, and `mimalloc` on the same workload, then compare RSS, throughput, and tail latency.
4. If a high-throughput allocator improves RSS, still inspect the allocation sites. The allocator may mitigate fragmentation while the root cause remains too many short-lived heap objects.
5. For embedded or `no_std`-friendly code, prefer bounded buffers and caller-provided storage where the API can support it. Heap fragmentation can be fatal on small heaps even when server builds tolerate it.

Report allocator experiments with the exact allocator, target OS, workload, duration, RSS metric, and any throughput or latency tradeoff.

### Measuring per-entry footprint

When RSS comes from many values that stay resident (caches, indexes, interned tables) and not from churn, a sampling profiler cannot see the cost. Count heap bytes per entry with a wrapper around `System`, and use it only in a benchmark or test binary:

```rust
use std::alloc::{GlobalAlloc, Layout, System};
use std::sync::atomic::{AtomicIsize, Ordering::Relaxed};

static LIVE_ALLOCS: AtomicIsize = AtomicIsize::new(0);
static LIVE_BYTES: AtomicIsize = AtomicIsize::new(0);

struct Counting;

// SAFETY: forwards every call to `System` unchanged. The counters are atomics
// and do not allocate. `realloc` uses the default impl, which calls these
// methods, so the counts stay balanced.
unsafe impl GlobalAlloc for Counting {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        // SAFETY: caller upholds `GlobalAlloc::alloc`'s contract; forwarded as-is.
        let ptr = unsafe { System.alloc(layout) };
        if !ptr.is_null() {
            LIVE_ALLOCS.fetch_add(1, Relaxed);
            LIVE_BYTES.fetch_add(layout.size().cast_signed(), Relaxed);
        }
        ptr
    }

    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        // SAFETY: `ptr` came from `alloc` above with this `layout`.
        unsafe { System.dealloc(ptr, layout) };
        LIVE_ALLOCS.fetch_sub(1, Relaxed);
        LIVE_BYTES.fetch_sub(layout.size().cast_signed(), Relaxed);
    }
}

#[global_allocator]
static GLOBAL: Counting = Counting;
```

Create the container with `with_capacity(N)` first, then snapshot `LIVE_BYTES`, insert N entries, and snapshot again. Because the slots were allocated before the first snapshot, `(after - before) / N` is only the out-of-line heap each entry owns (boxed slices, strings, nested `Vec`s). Add the inline slot once: `std::mem::size_of::<(K, V)>()` for a `HashMap`, or `size_of::<Entry>()` for a `Vec<Entry>`. A `HashMap` also spends one control byte per bucket and keeps buckets at a power of two no more than 7/8 full, so report that slack separately rather than folding it into the per-entry figure. Without pre-sizing, the delta mixes the inline slot, the out-of-line heap, and the container's spare capacity, which jumps at each resize, so bytes per entry would change with N. The counts are *requested* bytes. Allocator size-class rounding (for example jemalloc bins) makes the real footprint larger, so also compare `LIVE_ALLOCS` per entry, because each extra allocation adds rounding and a pointer to chase.

Rules for the benchmark:

1. **Match the production value mix.** Record types, lengths, and items per entry should follow observed distributions (the Cloudflare case study used 56% `A`, 25% `AAAA`, 19% variable-length). Uniform or tiny synthetic values hide enum-padding and size-class effects.
2. **Measure speed alongside memory.** Track insert throughput and lookup latency in the same harness, so a layout change that saves bytes but adds pointer chasing shows up.
3. **Confirm in production with steady-state RSS.** Restarted processes start with empty caches, so read the plateau after the cache refills, not the dip right after a deploy. Expect a smaller percentage win than the per-entry benchmark, because RSS also includes everything outside the cache.

Layout fixes are in `optimization.md` under "Shrinking long-lived data".

## Understanding the Output

### Self Time vs Total Time

- **Self time**: Time spent in the function itself (excluding callees)
- **Total time**: Time spent in function + all its callees

| Metric | High Value Means |
|--------|------------------|
| High self, low total | Function itself is slow |
| Low self, high total | Function calls slow code |
| Both high | Hot path, optimize this |

### Firefox Profiler UI Views

| View | Best For |
|------|----------|
| Call Tree | Understanding hierarchy |
| Flame Graph | Visual hot spot identification |
| Timeline | Finding slow phases |
| Stack Chart | Time-based call visualization |
