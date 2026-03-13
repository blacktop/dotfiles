# Fresh-Eyes Workflow

Source snapshot: refreshed 2026-03-13 from current Claude Code, Codex, and Gemini prompt/skill guidance.

## Core loop

### 1. Reconstruct scope

Before reviewing, identify:

- changed files
- untracked files
- generated artifacts
- tests touched or not touched
- commands already run

Prefer diff-first review over memory of what you intended.

### 2. Re-read the actual edits

Read:

- the diff
- the changed files
- neighboring code only where needed to resolve intent or risk

Do not immediately trust the explanation that accompanied the change.

### 3. Check these five buckets

#### Correctness and regressions

Look for:

- wrong conditionals
- nil, null, zero, or empty-string regressions
- unit mismatches
- off-by-one behavior
- stale variable names hiding behavior changes
- broken return values or error propagation

#### Edge cases and error handling

Look for:

- newly unhandled invalid input
- range and boundary issues
- silent fallback changes
- partial updates without rollback
- missing guard clauses

#### Tests and verification gaps

Look for:

- changed behavior without changed tests
- missing boundary-case coverage
- failing or unrun verification
- assertions that still reflect the old contract

#### Contract or interface drift

Look for:

- names that no longer match behavior
- CLI flags or config defaults that changed implicitly
- schema, API, or serialization mismatches
- docs or examples that now lie

#### Clarity and maintainability

Look for:

- confusing code paths
- hidden coupling
- misleading comments
- surprising behavior packed into a “small” refactor

### 4. Run a cheap verification step

Prefer the lightest meaningful check:

- targeted unit test
- lint or typecheck for touched files
- a reproducer command
- an existing smoke test

Verification is not optional if it is cheap and available.

### 5. Repair clear issues by default

Default to fixing an issue immediately when all of these are true:

- the bug is local and well-understood
- the fix does not widen scope
- the verification step is cheap
- the change does not need human product or architecture judgment

Stay review-only when:

- the user explicitly asked for review-only
- the fix would sprawl into multiple modules
- the change has security, migration, or API blast radius that needs explicit approval
- the right fix is unclear

After fixing, re-run the narrowest relevant verification and do one more quick pass on the changed files.

### 6. Report findings first

Use this shape:

```text
Finding: [short title]
Location: [file:line]
Why it matters: [direct explanation]
Suggested fix direction: [short concrete change]
```

If there are no substantive issues:

```text
No substantive issues found.
Verification: [commands]
Residual risk: [short note or none]
```

If you fixed issues, use this shape:

```text
Fixed: [short title]
Location: [file:line]
Why it mattered: [direct explanation]
Verification: [command or check]
```

## Escalation rule

If the change feels risky but evidence is incomplete:

- say what you checked
- say what remains uncertain
- recommend the next verification step

Do not overstate confidence.
