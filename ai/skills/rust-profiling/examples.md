# Examples

## Profiling Scenarios

### Profile a CLI Command

```bash
cargo build --profile profiling
samply record ./target/profiling/ipsw pkg extract payload.pkg --output /tmp/out
```

### Profile with Higher Resolution

For short-running commands, increase sampling rate:

```bash
samply record --rate 4000 ./target/profiling/myapp
```

### Profile Multiple Iterations

```bash
samply record --iteration-count 10 ./target/profiling/myapp
```

### Save for Later / CI Analysis

```bash
samply record --save-only -o profile.json ./target/profiling/myapp
# Later:
samply load profile.json
# Or analyze via CLI:
python3 ~/.claude/skills/rust-profiling/scripts/analyze_profile.py profile.json
```

### Profile Tests

```bash
# Build tests without running
cargo test --profile profiling --no-run

# Find the test binary
ls target/profiling/deps/<crate>-*

# Profile specific test
samply record ./target/profiling/deps/<test-binary> --test specific_test_name
```

### Profile a Benchmark

```bash
cargo bench --no-run
samply record ./target/release/deps/<bench-binary> --bench
```

## Analysis Examples

### Basic Analysis

```bash
python3 ~/.claude/skills/rust-profiling/scripts/analyze_profile.py profile.json
```

Output:
```
======================================================================
PROFILE SUMMARY
======================================================================
Total samples: 42,831
Unique functions: 1,247
Libraries: 12

======================================================================
LIBRARY BREAKDOWN (by self time)
======================================================================
Library                                    Self %     Total %    Funcs
----------------------------------------------------------------------
ipsw                                        67.2%      89.4%       423
liblzma.5.dylib                            18.3%      18.3%        12
libsystem_malloc.dylib                      8.1%       8.1%        24

======================================================================
HOT FUNCTIONS (by self time)
======================================================================
 Samples  Self%  Total%  Function
----------------------------------------------------------------------
   12847  30.0%   30.0%  lzma_decode
    4892  11.4%   45.2%  ota::pbzx::decompress_chunk
    2341   5.5%    5.5%  _malloc_zone_malloc
```

### Filter to Your Code

```bash
python3 ~/.claude/skills/rust-profiling/scripts/analyze_profile.py profile.json --lib ipsw
```

### Find Who Calls a Hot Function

```bash
python3 ~/.claude/skills/rust-profiling/scripts/analyze_profile.py profile.json --callers decompress_chunk
```

Output:
```
======================================================================
CALLERS OF: decompress_chunk
======================================================================
    4892 ( 11.4%)  ota::pbzx::ParallelPbzxReader::decompress_parallel
     127 (  0.3%)  ota::pbzx::PbzxReader::fill_buffer
```

### Show Call Tree

```bash
python3 ~/.claude/skills/rust-profiling/scripts/analyze_profile.py profile.json --tree
```

Output:
```
======================================================================
CALL TREE (min 1.0% of samples, depth 5)
======================================================================
 89.4% (12.1% self) main
└──  76.3% ( 8.2% self) pkg::reader::PackageReader::with_payload_parallel
    └──  67.1% ( 0.1% self) ota::pbzx::ParallelPbzxReader::new
        └──  67.0% ( 0.0% self) decompress_parallel
            └──  66.9% (30.0% self) decompress_chunk
```

### Compare Before/After

```bash
# Profile before optimization
samply record --save-only -o before.json ./target/profiling/myapp

# Make changes, rebuild
cargo build --profile profiling

# Profile after
samply record --save-only -o after.json ./target/profiling/myapp

# Compare
python3 ~/.claude/skills/rust-profiling/scripts/analyze_profile.py before.json --diff after.json
```

Output:
```
======================================================================
PROFILE COMPARISON
======================================================================
Before: 42,831 samples
After:  10,247 samples

======================================================================
BIGGEST CHANGES (by self time %)
======================================================================
 Before%  After%     Diff  Function
----------------------------------------------------------------------
  30.0%    2.1%   -27.9%  lzma_decode
  11.4%   45.2%   +33.8%  rayon_core::job::StackJob::run_inline
   5.5%    1.2%    -4.3%  _malloc_zone_malloc

Summary: 15 functions improved, 3 regressed (>0.5% change)
```

### Export for CI/Automation

```bash
python3 ~/.claude/skills/rust-profiling/scripts/analyze_profile.py profile.json --json > analysis.json
```

Then in CI, check for regressions:
```bash
jq '.functions[] | select(.name | contains("my_hot_function")) | .self_pct' analysis.json
```

## Optimization Workflow

1. **Baseline**: Profile current code, save as `baseline.json`
2. **Identify**: Find top 3 functions by self-time
3. **Analyze**: Use `--callers` to understand call patterns
4. **Optimize**: Make targeted change
5. **Verify**: Profile again, compare with `--diff baseline.json`
6. **Repeat**: Until satisfied with performance
