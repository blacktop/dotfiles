---
name: are-you-sure
description: One bounded fresh-eyes review of the change you just made, before you hand it back. Finds real bugs, regressions, safety problems and code that does not need to exist, fixes the clear ones, and stops. Use when the user asks "are you sure?", asks you to double-check, sanity-check, self-review or take a second look at your work, or before finalizing, committing or opening a PR for a change that touched behavior, configuration, tests or interfaces. Run it once per change; do not run it again on its own output.
---

# Are You Sure

You have just finished a change. Before you hand it back, take one second look at it with fresh eyes. This is a single review pass with a fixed end, not another round of development.

Treat code as a cost. Every line you leave behind has to be read, tested, secured and maintained for as long as the project lives, so the most valuable thing this pass can find, after a real bug, is code that does not need to exist. "I removed it" is a better outcome than "I improved it."

## What is worth changing

Change something only if a careful reviewer would refuse to merge without it:

- a bug, a regression, or behavior that does not match what was asked for
- a security, data-loss or resource-exhaustion risk
- a broken contract: a signature, flag, format, error or default that changed without being asked to
- code in this change that can be deleted without anyone noticing

Leave everything else alone. Names you would have chosen differently, comment wording, formatting, a slightly nicer structure, more tests for behavior that is already covered, and handling for situations that cannot happen all feel like progress. Each one is new unreviewed code, and together they are how a review turns into an endless polish loop.

Stay inside what changed. Do not tidy neighboring code unless a bug you are fixing requires it. If the user asked for review only, report findings and change nothing.

## The pass

1. **Rebuild the scope from the diff**, including untracked files, rather than from your memory of what you meant to do. Note which checks have already been run.

2. **Check the change against what was asked.** Re-read the request, then the diff. Does it do everything asked, and only that? Requirements that were quietly skipped and features nobody requested are both findings.

3. **Subtract.** For each function, file, flag, option, abstraction, dependency and test the change added, ask what would break for the user if it were gone. If the honest answer is nothing, remove it: unrequested options and parameters, a wrapper with one caller, an abstraction with one implementation, a copy of something the standard library or the repo already provides, defensive branches for states the callers cannot produce, compatibility shims, dead and commented-out code, and tests that duplicate each other, assert implementation details or mostly exercise a mock. A removal that would also change something a user can observe, such as message text, output format or an error kind, is not a free deletion; report it instead. For a deeper cleanup of a large change, use the `code-simplifier` skill instead of stretching this pass.

4. **Check what remains.**
   - Correctness: wrong conditions, off-by-one, empty, zero and nil inputs, error paths that swallow or mislabel a failure, state left half-updated, behavior that changed while its test did not.
   - Safety: untrusted input reaching a shell, query, path or deserializer; secrets in code, logs or errors; missing authorization; destructive operations without a guard; unbounded input, recursion, retries or memory; cancellation and timeouts that are accepted but ignored.
   - Efficiency: only what is visible without a profiler, such as I/O or queries inside a loop, work redone on every call, copies of large data, or a quadratic scan where a map would do.
   - Drift: comments, docs, help text and examples that the change made false.

5. **Write down the list of changes you will make before making any of them.** Then apply that list, run the narrowest checks that cover it, and stop. If a fix would widen scope, change architecture, or needs a product or security decision, do not guess: report it.

Tests are code too and follow the same rule. When you fix a bug that no test would have caught, add one test for it. Otherwise do not add, rewrite, reorganize or extend tests in this pass.

## When to stop

The pass is over when the list from step 5 is applied and verified. Do not start a second pass, and do not invoke this skill again on the result. Anything you notice while applying fixes goes in the report, not into the code. Finding nothing is a good result; say so plainly rather than looking for something to adjust. Do not overstate confidence either: if something looks risky and you could not check it, say what you checked and what remains uncertain.

This pass does not replace running the project's real verification, a dedicated security audit, or an independent second opinion on a high-risk change.

## Report

Keep it short, with file references, in this order:

1. Fixed: the issue, why it mattered, and the change.
2. Removed: what, and why nothing depends on it.
3. Verified: the commands you ran and their result.
4. Noticed but left alone: one line each, so the user can decide. Write "No substantive issues found" when that is the case.
