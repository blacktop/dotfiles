# Shell (Bash and Fish)

Match the script's dialect. A `#!/bin/sh` script stays POSIX, and a Fish function stays Fish. Let `shfmt` and `fish_indent` own formatting.

## Usually deletable

- argument parsing for flags nobody passes, and usage text that repeats itself
- a function with one caller that is shorter inlined
- temporary files where a pipe works, and a subshell or `eval` that does nothing
- hand-rolled versions of what `basename`, `dirname`, `mktemp`, parameter expansion or Fish's `string`, `path` and `math` builtins already do
- branches for an operating system or tool version the repo does not support; check the README, CI matrix and install scripts before deciding
- variables that are exported but read only by the script itself
- debug `echo` and `set -x` left by the current work

## Prove it is dead

- `shellcheck` reports unused variables (SC2034) and unreachable code (SC2317).
- `bash -n`, `sh -n` and `fish -n` catch syntax errors after an edit.
- Search the whole repo for a function name, including files that `source` the script.
- Fish autoloads `functions/*.fish`, `completions/*.fish` and `conf.d/*.fish` by file name, and abbreviations and key bindings are used interactively. A Fish function with no references in the repo is not dead; treat it as user-facing.
- Scripts run by cron, launchd, git hooks, CI or another repo have callers you cannot see with a search. Treat their flags and output as public.

## Tests

- The same rules apply to `bats` files and plain `sh` test scripts.
- Delete tests that only assert a stubbed binary was called when the script's output or exit status is already asserted.
- Merge cases that differ by argument into one loop with a label per case.
- Keep tests of error paths: missing file, non-zero exit of a dependency, interrupted run and cleanup.

## Keep

- `set -euo pipefail` (or `set -eu` in POSIX sh) and `trap` cleanup
- quoting, `--` before path arguments, and `mktemp` for anything written to a shared directory
- checks on arguments and environment that come from outside the script
- exit codes and messages that callers or users rely on
