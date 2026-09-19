---
name: handoff
description: >-
  This skill should be used when a user asks for an execution-ready prompt to
  hand work to another LLM agent or fresh session. Trigger phrases include
  "write a prompt for Claude/Codex/Gemini/Grok", "hand this off to another
  agent", "draft a directive for a worker", and "write a prompt so a fresh
  session can continue this". It drafts prompts only; it does not spawn, route,
  or supervise agents. Supports Claude, GPT/Codex, Gemini, Grok, and
  vendor-neutral targets.
---

# Handoff Prompt Generator

Generate the smallest prompt another agent can execute without guessing.

## When to use

Use this skill to draft an execution-ready prompt for a named LLM target or a
fresh session, in the caller's supplied model, account, and effort.

Do not use it to run, route, or supervise agents — that is `orchestrate`. Do not
draft a `tmux-pm` implementation directive here; render and validate that in
`tmux-pm` (see the commit-first overlay below). This skill produces prompt text
only.

## Preserve authority

Resolve the receiver in this order:

1. Exact model, account, harness, and effort supplied by the caller.
2. Supplied model family.
3. Vendor-neutral prompt.

Never reroute a caller-selected model, account, effort, permission mode, or
security lane. Do not add commit, signing, clean-worktree, review, or delegation
requirements unless the caller, repository, or orchestrator requires them.

Read only the matching target reference, one per named target:

| Target | Reference |
| --- | --- |
| Claude | [references/anthropic.md](references/anthropic.md) |
| GPT / Codex | [references/openai.md](references/openai.md) |
| Gemini | [references/google.md](references/google.md) |
| Grok | [references/xai.md](references/xai.md) |

Skip vendor references for a vendor-neutral target. If current model guidance
matters, verify it from the vendor's primary documentation. Report reference
drift; do not edit bundled references unless the user explicitly asks.

## Gather only execution-critical facts

Collect:

- one objective and its observable completion bar;
- verified current state, blockers, and assumptions;
- exact paths, branch/worktree, artifacts, and commands;
- owned and excluded scope;
- authorization and genuine stop conditions;
- required tools, evidence rules, and any delegation cap;
- verification commands and expected results;
- exact output or notification contract.

Prefer paths over copied history when the receiver shares the workspace. Prefer
a reference over a description: point at the source file, test, schema, or
mockup that already encodes the intent instead of paraphrasing it. Label unknown
facts with `[TODO: ...]` instead of inventing them.

## Base template

```text
Target: [exact model/account/harness/effort, family, or vendor-neutral]
Handoff type: [shared workspace | fresh context]

Objective
[One concrete outcome and why it matters]

Success criteria
- [Observable result]
- [Verification result]

Verified context
- [Current state, baseline, and blockers]
- [Paths, branch/worktree, artifacts, and commands]

Scope and authority
- Own: [paths or subsystem]
- Do not touch: [explicit exclusions]
- Stop for: [external authority, destructive action, or material scope change]

Tools and evidence
- [Tools or sources the receiver must use, and what each claim must cite]
- [Delegation: whether subagents are warranted, and the cap]

Verification
- [Exact commands or evidence checks]

Output
- [Deliverable location or exact response shape]
- [How to report blockers and skipped checks]
```

Apply only target-specific ordering or formatting that materially changes the
receiver's behavior. State every rule once. Do not paste large logs, repeat
permission prose, or ask for private chain-of-thought.

Write the completion bar, not the working method. Receivers that already verify
and self-correct are made worse by "double-check your work" or "verify before
responding"; the target reference says which ones. Exact commands listed under
Verification are a contract and stay.

## Commit-first overlay

When a `tmux-pm` lane is the consumer, do not draft the directive here. Render
the template in `~/.agents/skills/tmux-pm/SKILL.md` and prove it:

```fish
~/.agents/skills/tmux-pm/scripts/validate-directive.sh <directive-file>
```

That validator is the specification. It requires a PM pane ID, a signing mode,
a PM notification contract, exact commit and verification commands, and a
strict section order, and it rejects anything this skill invents on its own. Ask
the PM which signing mode applies rather than assuming one: the signed and
unsigned variants differ in completion bar, verification commands, and commit
command.

For a caller or repository that requires a checkpoint commit outside `tmux-pm`,
extend the base template rather than starting a second shape. Add owned paths,
the exact focused check and commit commands, and a single `DONE <ROLE>:
branch=<BRANCH> commit=<sha> ...` output line. Preserve any caller-supplied
retry limit exactly; do not invent one.

## Return

Return the ready-to-send handoff in one fenced block. List unresolved
assumptions after it. Return separate prompts only when target-specific tuning
actually differs.
