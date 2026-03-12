---
name: second-opinion
description: Run an external LLM code review with Codex CLI, Gemini CLI, or both. Use when the user asks for a second opinion, external review, Codex review, Gemini review, or wants a model-vs-model review of current changes, a branch diff, a specific commit, or a GitHub pull request.
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

- tool: `codex`, `gemini`, or `both`
- scope: `uncommitted`, `branch diff`, `commit`, or `PR`
- focus: `general`, `security`, `performance`, `error handling`, `architecture`, or a custom concern

Ask one concise follow-up only if a missing detail blocks the run.

## Read only what you need

- Read [references/workflow.md](references/workflow.md) for scope detection, diff sizing, review-brief construction, and synthesis rules.
- Read [references/codex.md](references/codex.md) only if running Codex.
- Read [references/gemini.md](references/gemini.md) only if running Gemini.

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
5. Run the selected tool or tools in parallel if independent.
6. Present findings first, then agreement and disagreement across tools.
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

1. Findings by tool, highest severity first.
2. Explicit `No findings` if a tool returns nothing substantive.
3. A short synthesis:
   - where the tools agree
   - where they disagree
   - what looks worth acting on first

Keep the synthesis separate from the raw reviewer output so the user can distinguish the outside opinion from your judgment.
