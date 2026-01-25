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
```

This gives:
- Release-level optimizations (accurate performance)
- Debug symbols (readable function names in profiler)

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
| `-p <PID>` | Attach to existing process (Linux only) |

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
python3 ~/.claude/skills/rust-profiling/scripts/analyze_profile.py [OPTIONS] <profile.json>
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
