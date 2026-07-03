---
name: rust-profiling
description: Profile Rust code using samply and related evidence to identify CPU bottlenecks, allocation hot paths, and allocator-fragmentation symptoms. Use when performance is slow, RSS grows unexpectedly, before optimizing, or when the user asks to profile.
---

# Rust Profiling with Samply

Profile Rust binaries to find CPU bottlenecks and allocation pressure using [samply](https://github.com/mstange/samply), then use OS-level memory evidence when RSS or fragmentation is the symptom.

## Quick Start

```bash
# 1. Ensure profiling profile exists in Cargo.toml (see reference.md)
# 2. Build with debug symbols
cargo build --profile profiling

# 3. Profile (opens Firefox Profiler UI)
samply record ./target/profiling/<binary> [args...]

# 4. Or save for CLI analysis
samply record --save-only -o profile.json ./target/profiling/<binary>
python3 ~/.agents/skills/rust-profiling/scripts/analyze_profile.py profile.json
```

## Skill Files

| File | Purpose |
|------|---------|
| `reference.md` | Cargo.toml setup, samply options, troubleshooting |
| `examples.md` | Common profiling scenarios and analysis patterns |
| `optimization.md` | Post-profiling fixes: source patterns, release-profile tuning, PGO, BOLT, what doesn't work |
| `scripts/analyze_profile.py` | CLI tool to analyze saved profile.json files |

## When to Use

- Performance is slower than expected
- RSS or heap usage grows unexpectedly under load
- Before optimizing (measure first!)
- After optimization (verify improvement)
- Investigating CPU-bound operations or allocation-heavy hot paths

## When NOT to Use

- The task is a Rust correctness bug, API design question, or refactor without a performance symptom.
- The user already has a narrow benchmark request that does not need profiling guidance.
- The issue is build time, binary size, or dependency hygiene rather than runtime CPU, memory, or contention.

## What to Look For

| Pattern | Meaning | Action |
|---------|---------|--------|
| High self-time | Function itself is slow | Direct optimization target |
| High total-time | Called often or slow callees | Check call frequency |
| `malloc`/`alloc` in hot path | Allocation overhead | Preallocate, reuse, pool, or use bounded/shared buffers |
| RSS grows then plateaus while profiles show allocation churn | Possible allocator fragmentation, not necessarily a leak | Compare allocators, then reduce high-rate small allocations |
| `pthread_mutex`/`parking_lot` | Lock contention | Reduce lock scope or use lock-free |
