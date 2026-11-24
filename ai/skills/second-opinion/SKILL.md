---
name: second-opinion
description: Run an external LLM code review with the Codex CLI or the Antigravity CLI (Gemini 4 Neon). Use when the user asks for a second opinion, external review, Codex, Gemini or Antigravity review, or wants a model-vs-model review of current changes, a branch diff, a specific commit, or a GitHub pull request.
---

# Second Opinion

Run an independent code review without changing the repo.

## When to use it

- non-trivial code changes
- risky refactors
- security, performance, or concurrency-sensitive edits
- schema or API changes
- before opening or merging a PR
- when the user explicitly wants another model's view

## When to skip it

- docs-only or formatting-only changes, unless the user still wants it
- repos or diffs that must not be sent to external services
- empty diffs

If repository guidance or user instructions forbid sending code to third-party tools, stop and ask before proceeding.

## Infer the request first

Infer as much as possible from the user's message:

- scope: `uncommitted`, `branch diff`, `commit`, or `PR`
- focus: `general`, `security`, `performance`, `error handling`, `architecture`, or a custom concern
- reviewer: `Codex`, `Antigravity`, or both; when the user names none, pick one that is not the model running this session

Ask one concise follow-up only if a missing detail blocks the run.

## Read only what you need

- Read [references/workflow.md](references/workflow.md) for scope detection, diff sizing, review-brief construction, and synthesis rules.
- Read [references/codex.md](references/codex.md) for the Codex CLI commands and flags.
- Read [references/antigravity.md](references/antigravity.md) for the `agy` command, model and result checks.

## Core workflow

1. Detect the scope and compute diff stats.
2. Stop on empty diffs.
3. Warn on large diffs and suggest narrowing scope before spending tokens.
4. Build a short review brief that tells the reviewer:
   - what changed
   - what to focus on
   - how to inspect the diff locally
   - that the review is read-only
   - what output format to return
5. Run the review with each chosen reviewer.
6. Present each reviewer's findings first, then where you agree and disagree with them.
7. Never auto-apply suggested fixes unless the user explicitly asks.

## Safety defaults

- Keep the review read-only.
- Do not commit, push, stage, or edit files as part of the second opinion run.
- Prefer tool-native review commands over manual diff pasting when the tool can inspect the repo directly.
- Prefer prompt files or stdin over fragile one-line shell quoting for long review briefs.
- Use explicit timeouts and capture output cleanly when automating external review CLIs.
- Clean up temporary prompt and output files after reading them.

## Review result format

Present results in this order:

1. Each reviewer's findings, highest severity first.
2. Explicit `No findings` if a reviewer returns nothing substantive.
3. A short synthesis:
   - where you agree with the reviewers
   - where you disagree, and why
   - what looks worth acting on first

Keep the synthesis separate from the raw reviewer output so the user can distinguish the outside opinion from your judgment.
