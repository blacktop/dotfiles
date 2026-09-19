# OpenAI GPT-6 Astra / GPT-5.6 / Codex Handoff Patterns

Source snapshot: verified 2026-09-15 from official OpenAI docs.

- [Using GPT-6 Astra (model guidance and prompting best practices)](https://developers.openai.com/api/docs/guides/latest-model)
- [Rethinking skills and prompts for GPT-6 Astra](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra)
- [Codex model selection](https://developers.openai.com/codex/models)
- [Codex best practices](https://developers.openai.com/codex/learn/best-practices)
- [Codex subagents](https://developers.openai.com/codex/subagents)
- [OpenAI Daybreak: Trusted Access for Cyber overview](https://help.openai.com/en/articles/20001258-trusted-access-for-cyber-overview)
- [Codex prompting guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide) — supplementary agent-harness guidance; prefer the Astra and GPT-5.6 pages when they differ.

## Current lineup

| Model | Best handoff shape |
| --- | --- |
| `gpt-6-astra` | Default flagship for complex, ambiguous, high-value implementation, review, and analysis needing judgment and follow-through |
| `gpt-5.6-sol` | Strong balance of capability and efficiency; feature implementation and research synthesis when Astra is not required |
| `gpt-5.6-terra` | Faster read-heavy exploration, tests, triage, and large-file review |
| `gpt-5.6-luna` | Clear, repeatable, high-volume extraction, classification, transformation, and structured summaries |

The restricted cyber-tier models (`gpt-5.6-cyber`) are listed under Daybreak
below, not here.

`gpt-6-astra` is the general-work default. Astra at `low` reaches Sol-at-`high`
capability at the lowest cost, but OpenAI recommends `medium` as the default
drop-in for former Sol/high implementation work — see effort selection below.
Use an explicit model when the caller has already routed the task. Never let prompt
optimization replace a supplied model, account, or reasoning effort. The `none`
reasoning level is gone on Astra; GPT-5.6 models still accept it.

## Family-wide best results

- Use a lean contract: outcome, important constraints, available evidence,
  completion bar, output shape, and stop conditions. Leaner prompts score higher
  and cost less on Astra; state each instruction exactly once.
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
- When the caller, repository, or orchestrator explicitly requires a checkpoint
  commit, define its validation, signing, and cleanliness policy as the
  completion unit. Otherwise do not add version-control delivery requirements.
- Add an external reviewer only when explicitly authorized. When delegation is
  authorized, prefer parallel agents for bounded read-heavy work, not
  overlapping write-heavy implementation.
- For multi-step work, request a short initial update and sparse outcome-based
  milestone updates, not narration of routine tool calls.

## GPT-6 Astra behavior and tuning

Astra is more capable, more literal, and more aligned than Sol, so prompts
written to steer earlier models can now misfire. Audit any inherited skill,
`AGENTS.md`, or task-prompt text before reusing it with Astra.

- **Follow-through and persistence.** Astra can be more tentative than Sol about
  when to stop and may return a first implementation while work remains. Define
  completion before starting and make the full arc part of the request:
  implement, run it, inspect the result, and fix what fails. A "stop for review
  after the first pass" instruction pulls Astra toward an early exit, so include
  it only when that checkpoint is a decision you actually need.
- **Instruction following.** Astra follows instructions in prompts, skills, and
  `AGENTS.md` more precisely, which gives more control but also means stale or
  contradictory guidance bites harder. Keep the prompt to what the task needs;
  do not require reading a stack of docs before every edit.
- **Decision boundaries.** As the most aligned model, Astra will not take unsafe
  actions and exercises good judgment. Strong "ask first" or "stop and wait"
  language added to restrain older models can make Astra over-pause on safe,
  in-scope work. Keep only genuine invariants; grant explicit permission for
  workflows you know are safe (for example, a disposable local test suite).
- **No self-check prose.** Astra runs tests and verifies its work on its own and
  over-does it when told to. Do not add "run the tests," "double-check," or
  "verify before responding." Exact commands under a Verification section are a
  contract and stay.
- **Style and length.** Astra tends toward detailed, formatted responses and can
  reuse recurring phrases. Specify the writing style, structure, and length your
  output needs rather than relying on defaults.
- **Subagent delegation.** Astra delegates readily. Say whether subagents are
  warranted and cap them; in a single-owner workflow, forbid the worker from
  spawning its own fleet.

## Effort selection

Astra reasoning effort is `low`, `medium`, `high`, `xhigh`, and `max`.

- `low` reaches Sol-at-`high` capability at the lowest cost; use it for
  read-heavy exploration, inventory, and triage.
- `medium` is the balanced default for one-shot implementation, review, and
  analysis. It is the recommended drop-in for former Sol/high work: `low`
  matches that capability, but `medium` adds headroom for little extra cost.
- `high` earns its cost in a long autonomous loop that calls tools many times
  before reporting, where a wasted turn costs a whole round trip.
- `xhigh` and `max` are for a task where you have measured a failure at `high`.
  Effort cannot supply missing scope, context, or access; fix the prompt first.

Preserve the caller's selection. Do not escalate effort to compensate for a
vague objective or missing tests.

## Cyber work: OpenAI Daybreak tiers

Cybersecurity, reverse-engineering, and vulnerability-research handoffs route to
the Daybreak models, not Astra — Astra does not carry reduced refusals for most
Daybreak customers. Both require an approved Daybreak account; do not draft a
handoff assuming access the caller has not confirmed, and do not assume Daybreak
Red access from Daybreak Blue.

| Access | Model / alias | Draft handoffs for |
| --- | --- | --- |
| Daybreak Blue | `gpt-daybreak-blue-latest` (resolves to `gpt-5.6-sol`) | Defensive work: secure code review, vulnerability triage and validation, malware analysis, detection engineering, incident response, and patch validation. |
| Daybreak Red | `gpt-daybreak-red-latest` (resolves to `gpt-5.6-cyber`) | Advanced authorized work: proof-of-concept exploit development and exploit-chain validation, penetration testing, red teaming, and controlled vulnerability research. |

When drafting a Daybreak handoff:

- State the authorized scope explicitly — the exact systems, repositories, or
  targets the receiver may act on, and that the work is authorized and
  defensive or authorized-offensive. These prompts resemble malicious activity
  without that framing.
- Keep execution isolated: sandboxed environment, least-privilege permissions,
  no production systems or open internet unless the authorized scope covers it.
- Keep human review for high-impact findings and for any action beyond the
  sandbox. For a Daybreak Red exploit handoff, stop before credential access,
  persistence, or production change unless explicitly authorized.
- Route defensive slices to Daybreak Blue and reserve Daybreak Red for slices
  that genuinely need offensive capability. Use the GPT-5.6 effort ladder and
  default to `high` for quality-first security work.

## Runtime settings

Keep runtime controls in the harness when available:

- Preserve the caller's model and reasoning effort. Reserve `max` for the
  hardest quality-first tasks rather than recommending it globally.
- Use `text.verbosity` for a stable response-length default; use the prompt for
  task-specific required content.
- Preserve reasoning state with `previous_response_id` or `reasoning.context`
  when the API harness supports it. Do not paste these API controls into a
  normal Codex CLI handoff.
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
- silently changing the selected model or effort;
- inherited "ask first," "double-check," or read-everything prose that makes
  Astra over-pause, over-verify, or burn context;
- repeated or contradictory permission rules;
- vague goals such as “improve this” or hidden completion criteria;
- escalating effort to compensate for missing scope, evidence, or verification;
- routing cyber work to Astra, or assuming Daybreak access the caller has not
  confirmed;
- asking for private reasoning instead of conclusions and supporting evidence.
