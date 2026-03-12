# Review Workflow

Source snapshot: refreshed 2026-03-12 from official and current tool sources

- OpenAI Codex CLI docs and changelog
- OpenAI Codex prompting and non-interactive guidance
- OpenAI AGENTS.md guidance
- Gemini CLI local help and installed extension metadata
- Gemini prompting guidance

## Scope detection

### Default branch

Use:

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

Fallback to `main`, then `master`, only if detection fails.

### Uncommitted scope

Show both tracked changes and untracked files:

```bash
git diff --stat HEAD
git diff --name-only HEAD
git ls-files --others --exclude-standard
```

### Branch diff scope

```bash
git diff --stat <base>...HEAD
git diff --name-only <base>...HEAD
```

### Specific commit scope

```bash
git diff --stat <sha>~1..<sha>
git diff --name-only <sha>~1..<sha>
```

### GitHub PR scope

Use PR-aware tooling only when the user actually asked for a PR review and the local environment has the needed GitHub context.

## Empty and large diff handling

Stop if the diff is empty.

Warn before running an expensive second opinion when the diff is large. Good default warning thresholds:

- more than 40 changed files
- more than 2000 changed lines

When warning, recommend narrowing to:

- a specific file set
- a single commit
- a branch diff against the real base
- one focus area at a time

## Review brief

Do not paste the full diff if the external reviewer can inspect the repo locally. Give a short brief plus the exact git command to run.

Use this structure:

```text
Review this code change set in read-only mode.

Focus:
- [general | security | performance | error handling | architecture | custom]

Scope:
- [uncommitted | branch diff vs <base> | commit <sha> | PR <id>]

What changed:
- [1-3 sentence summary]

Review constraints:
- Do not modify files.
- Do not commit, push, or stage changes.
- Prioritize correctness, security, performance, maintainability, and test gaps.
- Skip style-only comments unless they block understanding.

Repository guidance:
- Read AGENTS.md if present.
- If AGENTS.md is absent but CLAUDE.md exists, read CLAUDE.md.

Diff access:
- Run: [exact git diff command]
- For untracked files, also inspect: [file paths or `git ls-files --others --exclude-standard`]

Output format:
- Findings first, grouped by severity.
- For each finding: title, file:line if available, why it matters, and a concrete fix direction.
- If no substantive issues are found, say so explicitly.
```

## Best-practice prompts

- Keep the brief short and operational.
- Tell the reviewer how to inspect the diff instead of flooding it with raw patch text.
- Separate focus, scope, constraints, and output contract with labels.
- Use one reviewer per concern when the user wants multiple perspectives.

## Synthesis rules

After collecting outputs:

- findings first
- agreement summary second
- disagreements third
- your recommended next actions last

Do not collapse disagreements into false consensus.
