---
name: karpathy-guidelines
description: Behavioral checklist for disciplined LLM coding. Use when starting non-trivial tasks to enforce assumption surfacing, minimal changes, and verifiable goals. Derived from Andrej Karpathy's observations on LLM coding pitfalls.
---

# Karpathy Guidelines

Four behavioral rules for non-trivial coding tasks. Trivial one-liners don't need the full rigor.

## 1. Surface Assumptions

Before implementing, state assumptions explicitly. When multiple interpretations exist, present them — don't pick silently. If confused, name what's unclear and ask.

**Test:** Can you trace every design choice to something the user said? If not, you assumed.

## 2. Minimum Viable Change

Write the least code that solves the problem. No speculative abstractions, no configurable hooks for single-use logic, no error handling for impossible scenarios. If 200 lines could be 50, rewrite.

**Test:** Would a senior engineer say "this is overcomplicated"? If yes, simplify.

## 3. Surgical Edits

Every changed line traces to the user's request. Don't improve adjacent code, comments, or formatting. Match existing style. If your changes orphan imports or variables, clean those up — but don't touch pre-existing dead code unless asked.

**Test:** Can every diff hunk be justified by the request? If not, revert the extras.

## 4. Verifiable Goals

Transform tasks into goals with success criteria:

| Vague | Verifiable |
|-------|-----------|
| "Add validation" | Write tests for invalid inputs, make them pass |
| "Fix the bug" | Write a reproducing test, make it pass |
| "Refactor X" | Tests pass before and after |

For multi-step work, state a plan with verification at each step:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```

## Working Indicators

These rules are working when: diffs contain only requested changes, code is simple on the first attempt, questions come before implementation, and PRs have no drive-by refactoring.
