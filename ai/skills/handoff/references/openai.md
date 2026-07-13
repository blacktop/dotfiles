# OpenAI GPT-5.6 / Codex Handoff Patterns

Source snapshot: refreshed 2026-07-12 via Exa from official OpenAI docs.

- [GPT-5.6 Sol and family prompting guidance](https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6)
- [GPT-5.6 model guide](https://developers.openai.com/api/docs/guides/latest-model)
- [Codex model selection](https://developers.openai.com/codex/models)
- [Codex best practices](https://developers.openai.com/codex/learn/best-practices)
- [Codex subagents](https://developers.openai.com/codex/subagents)
- [Codex prompting guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide) — supplementary agent-harness guidance; prefer the GPT-5.6 pages when they differ.

## Current lineup

| Model | Best handoff shape |
| --- | --- |
| `gpt-5.6-sol` | Complex, ambiguous, open-ended, or high-value work needing judgment, depth, and polish |
| `gpt-5.6-terra` | General implementation, open-ended exploration, read-heavy scans, and pragmatic agent work |
| `gpt-5.6-luna` | Clear, repeatable, high-volume extraction, classification, transformation, and structured summaries |

`gpt-5.6` currently aliases Sol. Use an explicit variant when the caller has
already routed the task. Never let prompt optimization replace a supplied
model, account, or reasoning effort.

## Family-wide best results

- Use a lean contract: outcome, important constraints, available evidence,
  completion bar, output shape, and stop conditions.
- Describe the destination rather than prescribing every step. Remove repeated
  rules, redundant examples, obsolete scaffolding, and irrelevant tools.
- Reserve `ALWAYS`, `NEVER`, `must`, and `only` for real invariants. Use
  decision rules for judgment calls such as when to search, retry, or ask.
- Define autonomy and approval boundaries once: distinguish review/diagnosis
  from implementation, safe local work from external writes, and reversible
  actions from destructive or scope-expanding ones.
- State what evidence is required and what to do when it is missing. Absence of
  evidence is not automatically a factual negative.
- Give a retrieval budget for research: what needs support, what counts as
  sufficient, and the smallest useful fallback.
- Name the validation that matters. Require honest reporting when a check
  fails, is skipped, or cannot run.
- For multi-step work, request a short initial update and sparse outcome-based
  milestone updates, not narration of routine tool calls.

## Variant-specific tuning

### Sol

- Hand it the hard, quality-first outcome and leave room for judgment.
- Define ambiguity and approval rules so autonomy does not become scope drift.
- Include a strong completion bar and evidence-backed final verification.
- Keep the handoff compact even at `max`; more prompt scaffolding is not a
  substitute for a clear objective or tests.

### Terra

- Name the relevant paths, current behavior, intended change, and checks.
- Let Terra explore when the path is not yet known; define what evidence ends
  exploration and authorizes implementation.
- Keep the output practical. Do not add broad “flagship polish” instructions
  that expand a routine worker slice.

### Luna

- Make the operation deterministic: identify the complete input set, exact
  transformation/classification rule, output schema, and edge-case policy.
- Define a stopping condition and how to represent unknown or malformed items.
- Do not give Luna an ambiguous architecture, root-cause, or open-ended coding
  task; reroute such work to Terra or Sol outside the prompt.

## Runtime settings

Keep runtime controls in the harness when available:

- GPT-5.6 reasoning efforts include `none`, `low`, `medium`, `high`, `xhigh`,
  and `max`. Preserve the caller's selection. Reserve `max` for the hardest
  quality-first tasks rather than recommending it globally.
- Use `text.verbosity` for a stable response-length default; use the prompt for
  task-specific required content.
- Preserve reasoning state with `previous_response_id` or unmodified phase
  values when the API harness supports it. Do not paste these API controls into
  a normal Codex CLI handoff.
- Expose only task-relevant tools. Parallelize independent reads; keep dependent
  actions sequential and synthesize before acting.

## Good shape

```text
Role
[Function and collaboration style only if it changes behavior]

Goal
[User-visible outcome and why it matters]

Success criteria
- [Observable result]
- [Validation and evidence bar]

Evidence and context
- [Verified facts, paths, logs, reproduction]

Constraints and authority
- [True invariants, scope, allowed local actions, approval boundaries]

Tools and retrieval
- [Relevant tools and evidence budget]

Output
- [Artifact or response schema]

Stop rules
- [When to retry, fallback, ask, abstain, or stop]
```

## Avoid

- prompt stacks written for older GPT/Codex generations without re-evaluation;
- silently changing the selected Sol/Terra/Luna variant or effort;
- repeated or contradictory permission rules;
- vague goals such as “improve this” or hidden completion criteria;
- escalating effort to compensate for missing scope, evidence, or verification;
- asking for private reasoning instead of conclusions and supporting evidence.
