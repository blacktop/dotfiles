---
name: rust-profiling
description: Profile Rust code using samply to identify CPU bottlenecks. Use when performance is slow, before optimizing, or when the user asks to profile.
---

# Rust Profiling with Samply

Profile Rust binaries to find CPU bottlenecks using [samply](https://github.com/mstange/samply).

## Quick Start

```bash
# 1. Ensure profiling profile exists in Cargo.toml (see reference.md)
# 2. Build with debug symbols
cargo build --profile profiling

# 3. Profile (opens Firefox Profiler UI)
samply record ./target/profiling/<binary> [args...]

# 4. Or save for CLI analysis
samply record --save-only -o profile.json ./target/profiling/<binary>
python3 ~/.claude/skills/rust-profiling/scripts/analyze_profile.py profile.json
```

## Skill Files

| File | Purpose |
|------|---------|
| `reference.md` | Cargo.toml setup, samply options, troubleshooting |
| `examples.md` | Common profiling scenarios and analysis patterns |
| `scripts/analyze_profile.py` | CLI tool to analyze saved profile.json files |

## When to Use

- Performance is slower than expected
- Before optimizing (measure first!)
- After optimization (verify improvement)
- Investigating CPU-bound operations

## What to Look For

| Pattern | Meaning | Action |
|---------|---------|--------|
| High self-time | Function itself is slow | Direct optimization target |
| High total-time | Called often or slow callees | Check call frequency |
| `malloc`/`alloc` in hot path | Allocation overhead | Pool, arena, or stack allocate |
| `pthread_mutex`/`parking_lot` | Lock contention | Reduce lock scope or use lock-free |
