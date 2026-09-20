---
name: code-simplifier
description: Subtraction-first cleanup of code and tests. Deletes code that does not need to exist, collapses needless indirection, and prunes tests that protect nothing, while preserving the behavior people rely on and keeping the result fast and safe. Use after implementing or modifying code, when invoked as `$code-simplifier`, and whenever the user asks to simplify, clean up, slim down, de-bloat, reduce, remove dead code, cut over-engineering, or prune, trim or delete low-value, redundant or unnecessary tests, even if they only say a diff or PR is too big, has too much code, or has too many tests.
---

# Code Simplifier

Code is a cost. Every line left behind has to be read, tested, secured and maintained for as long as the project lives, and that includes test code. The aim of this skill is the smallest code that still does everything people rely on, and does it quickly and safely.

Measure the pass by what you removed. Swapping one expression for an equivalent nicer one removes nothing, produces churn a reviewer has to read, and is how a cleanup turns into endless polishing. Make that kind of edit only when it removes a real hazard or a real reading cost. The same goes for text: leave error messages, log lines, names and comments alone when they are accurate, even if you would have worded them differently.

## Scope

The default scope is the current change: `git diff` against the base branch plus untracked files. If the user names files, a package or a directory, that is the scope instead.

Leave the scope only to delete code your simplification orphaned, and to fix comments or docs your change made false.

What counts as behavior depends on whether anyone can depend on it yet:

- Code that is already committed or released has users. Keep its signatures, exported types, CLI flags, output and persistence formats, error behavior and side effects exactly as they are.
- Code added in the current change has no users yet. A flag, option, parameter, config key or extension point that the task did not ask for can go.

Project instructions (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`) and the surrounding code's style override this skill and its language guides.

## Before editing

1. Establish the scope and record its size with `git diff --shortstat` (or a line count of the named files), so the report can show the difference.
2. Run the focused tests for the scope. If they are already failing, record that and do not mix repairs into this pass.
3. Read the guide for each language in scope, and read `tests.md` if any test code is in scope. Each guide lists what is usually deletable, how to prove something is dead, how to prune tests, and what to keep:
   - `.go`: `languages/go.md`
   - `.rs`: `languages/rust.md`
   - `.swift`: `languages/swift.md`
   - `.py`, `.pyi`: `languages/python.md`
   - `.js`, `.jsx`, `.mjs`, `.cjs`, `.ts`, `.tsx`, `.mts`, `.cts`: `languages/javascript.md`
   - `.sh`, `.bash`, `.fish`, and extensionless scripts with a shell shebang: `languages/shell.md`
   - `.css`, `.scss`, `.sass`: `languages/css.md`

   For any other language, apply the general rules here.

## The pass, in order of payoff

Work top-down and stop at the first step that no longer finds anything; the later steps pay less.

1. **Delete.** For each function, type, file, flag, option, branch and dependency in scope, ask what stops working for a user if it is gone. If the answer is nothing, delete it. Usual finds: options nobody sets, parameters every caller passes the same value for, handling for states the callers cannot produce, compatibility shims with no remaining old side, commented-out code, debug logging, and comments that restate the code.
2. **Collapse indirection.** Inline what has one user: a wrapper with one caller, an interface or trait with one implementation, a builder or options struct for two fields, a generic instantiated with one type, a layer that only passes arguments through, config plumbing for what is really a constant.
3. **Replace with what already exists.** Prefer the standard library, a helper already in the repo, or a dependency already in use over hand-rolled code. Never add a dependency to simplify.
4. **Simplify what remains**, only where it lowers real reading cost: flatten nesting with early returns, remove mutable flags and temporary state, merge logic that is truly duplicated and has more than one meaningful caller. Do not merge cases that merely look alike.
5. **Prune tests** as described below.
6. **Chase orphans and stale references** until removing one thing no longer orphans another.

## Keep it fast and safe

Shorter is not better if it is slower or less safe. Do not simplify away:

- validation of untrusted input, authorization checks, bounds and size limits, timeouts and retry caps
- error propagation and the context that makes an error actionable
- cleanup and rollback paths, locking, and code that keeps working after a failure while reporting it
- an algorithmic choice: do not turn a map lookup into a linear scan, add I/O or allocation inside a loop, or drop a cache or fast path for brevity

A check is "defensive" only when you have shown no caller can produce the state it guards. At a trust boundary (user input, network, files, FFI, another process), keep it. If a removal would change performance characteristics or safety, leave it and mention it in the report.

## Tests

A test earns its place when it would fail for a bug a user would care about and no other test fails for the same bug. Everything else is code that slows the suite, breaks on refactors and gives false confidence. Read `tests.md` for what to delete, how to show a deletion is safe, and what never to remove.

- Tests added in the current change: prune them directly.
- Tests that were already committed: prune them when the user asked for test cleanup or named them in the scope. Otherwise list the candidates in the report and leave them.
- Never delete or weaken a test because it fails. That hides a bug; it does not simplify anything.

## Orphans and stale references

Deleting code orphans other code: functions, types, constants, imports, fixtures, test helpers, files and dependencies. Confirm each with a repo-wide search and the compiler, linter or dead-code tool named in the language guide before removing it. Be careful with anything reached without a direct reference: public API of a library, reflection, string dispatch, templates, generated code, plugin or command registration, and files loaded by name or convention.

In files you are editing, fix or delete comments, docstrings and docs that describe code or reasons that no longer exist. Do not invent a new rationale for a comment; if the reason is unknown, delete it.

## Finish

1. Rerun the focused tests, linters, type checks and formatters for the touched code.
2. Run `git diff --shortstat` again. The pass should be net-negative. If it is not, revert the parts that only moved code around, or explain why the extra lines are worth it.
3. Stop after one pass. Anything else you notice goes in the report, not into the code. Finding little to remove is a fine result; say so rather than looking for something to adjust.
4. Do not commit or stage unless asked.

## Report

Keep it short, with file references:

1. Removed: what, and why nothing depends on it.
2. Tests removed or merged: which ones, and what still covers the behavior.
3. Simplified: the few structural changes, if any.
4. Numbers: lines before and after, test count before and after, coverage before and after when measured.
5. Verified: commands run and their result.
6. Left alone: what you chose not to touch because it risked behavior, performance, safety or public API, and candidates that need the user's decision.
