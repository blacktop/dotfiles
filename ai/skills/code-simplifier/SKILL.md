---
name: code-simplifier
description: Behavior-preserving cleanup for recently changed code. Use after implementing or modifying code, when explicitly invoked as `$code-simplifier`, or when the user asks to simplify, clean up, or refactor the current diff without widening scope.
---

# Code Simplifier

## Contents

- [When to Use](#when-to-use)
- [When NOT to Use](#when-not-to-use)
- [Scope](#scope)
- [Before Editing](#before-editing)
- [Core Rules](#core-rules)
- [Unused Code](#unused-code)
- [Stale References](#stale-references)
- [Language Guides](#language-guides)
- [After Editing](#after-editing)
- [Final Response](#final-response)

Simplify recently changed code for clarity, consistency, and maintainability while preserving exact behavior. Prefer readable, explicit code over cleverness or line-count reductions.

## When to Use

- Use after the agent has written or modified code and should tighten the current diff before final verification.
- Use when the user invokes `$code-simplifier` or asks to simplify, clean up, refactor, reduce duplication, or remove unnecessary complexity.
- Use during final review when local cleanup can improve maintainability without changing APIs, outputs, side effects, or observable behavior.

## When NOT to Use

- Do not start a broad refactor or architecture rewrite.
- Do not change public APIs, exported types, CLI flags, output formats, persistence formats, or externally visible behavior.
- Do not simplify code that is outside the current diff unless it is directly orphaned by the change or is stale inside a file already being edited.
- Do not touch tests unless the user asked, the tests were already part of the current change, or a behavior-preserving cleanup requires removing now-stale test-only helpers.
- Do not add dependencies, compatibility layers, or speculative abstractions.

## Scope

Default scope is the current session's touched files and the current `git diff` against the base branch.

Two narrow exceptions may leave the diff:

- code orphaned by the simplification chain
- stale comments, docs, or names that now falsely describe behavior changed in the current work

Stay surgical. If cleanup grows beyond the current concern, crosses unrelated ownership boundaries, or expands the diff by roughly more than 50 lines, stop and report the proposed cleanup before continuing.

## Before Editing

1. Check the current diff and identify the files actually in scope.
2. Read the nearest `AGENTS.md`, `CONTRIBUTING.md`, and local surrounding code that controls style.
3. If relevant tests are cheap and the baseline is unknown, run a focused baseline first. If the baseline is already red, record it and avoid mixing simplification with unrelated failure repair.
4. For each language present in the changed files, read the matching file under `languages/` and apply it only where it agrees with repo instructions and surrounding style.

## Core Rules

- Preserve behavior exactly. No API, signature, output, error, timing, persistence, or permission behavior changes.
- Apply project standards first. User instructions, `AGENTS.md`, and nearby patterns override this skill and language guides.
- Prefer clarity over brevity. A clear one-liner is fine; a dense clever expression is not.
- Flatten unnecessary nesting with early returns or guard clauses when that improves readability.
- Prefer statements over nested expressions. Do not introduce nested ternaries or clever chains.
- Remove redundant code, redundant abstractions, and one-call helpers when inlining makes the result clearer.
- Do not add abstractions. Only extract a helper when it removes real repeated complexity and has more than one meaningful caller.
- Keep imports in the repo's established order. Do not churn imports just for style.
- Delete comments that restate the code. Keep or improve comments that explain why the code exists.
- Prefer standard library and existing dependencies over adding a package.
- Keep default visibility private. Do not expose items unless the existing public API requires it.
- Use DRY when it improves the code, but do not merge unrelated cases just because they look similar.

## Unused Code

Simplification can orphan code. After edits, look for now-unreferenced functions, methods, types, constants, variables, imports, and files.

In scope:

- code directly orphaned by the current simplification, even if the reference chain leaves the edited file
- code already stale inside files being edited

Out of scope:

- unrelated repo-wide dead-code hunts
- exported or public API surfaces that external consumers might call
- plugin, reflection, string-dispatch, template, generated-code, or configuration registrations unless the repo's tools prove they are dead

Confirm before deleting. Search the whole repo for references and lean on the compiler, linter, or type checker where available. Repeat until deleting one item no longer orphans another in the current chain.

## Stale References

Code cleanup can make comments, docstrings, local names, and docs false.

- In files being edited, update or delete comments and docstrings that describe removed reasons, old workarounds, or behavior that no longer exists.
- When the change retires a specific named workaround or concept, search for that exact concept and fix references that are now false.
- Do not rename exported/public identifiers solely for wording cleanup.
- Do not invent a new rationale. Delete false comments unless the new reason is known.

## Language Guides

Read only the guides matching changed file extensions:

- `.css`, `.scss`, `.sass`: `languages/css.md`
- `.go`: `languages/go.md`
- `.js`, `.jsx`, `.mjs`, `.cjs`: `languages/javascript.md`
- `.py`, `.pyi`: `languages/python.md`
- `.rs`: `languages/rust.md`
- `.ts`, `.tsx`, `.mts`, `.cts`: `languages/typescript.md`

If a guide is missing or conflicts with repo instructions, proceed with the general rules and note the conflict only when it affected the cleanup.

## After Editing

1. Rerun focused tests, linters, type checks, or formatters that cover the touched code.
2. Confirm the final diff is narrower, clearer, and behavior-preserving.
3. Check for new unused-code warnings.
4. Do not commit. Leave staging and commit messages to the user unless explicitly asked.

## Final Response

Summarize the simplification in behavior-preserving terms:

- what was cleaned up
- what verification ran and whether it passed
- any skipped cleanup because it risked behavior or public API changes
