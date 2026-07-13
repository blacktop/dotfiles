---
name: handoff
description: >-
  Generate execution-ready, model-specific prompts for handing work to a
  different LLM agent or fresh session. Use for shared-workspace delegation,
  cold-start continuation, cross-model transfer, one-shot worker directives,
  or requests such as "create a handoff prompt", "delegate this", "hand this
  off", and "prepare context for another agent". Supports current Anthropic
  Claude, OpenAI GPT/Codex, Google Gemini, and xAI Grok families.
version: 2.0.0
---

# Handoff Prompt Generator

Generate the smallest prompt another agent can execute without guessing.

## When to Use

- Delegate one bounded task to an agent that shares the current workspace.
- Continue work in a fresh session, after `/clear`, or on another platform.
- Transfer work between model families and apply the receiver's preferred
  prompt structure.
- Prepare a one-shot worker directive when another orchestrator owns routing,
  supervision, lifecycle, and integration.
- Produce separate optimized prompts for multiple target models.

## When NOT to Use

- Save a session identifier for later resumption; use `save-session`.
- Decompose and execute subtasks from this session; use `orchestrate`.
- Supervise live tmux agents continuously; use `tmux-pm`. This skill may tune
  a worker directive, but does not own routing, panes, merges, or DONE messages.
- Continue in the same conversation when no context boundary exists.

## Choose the Handoff Mode

- **Shared workspace:** receiver can inspect the same repo, files, branches,
  worktrees, logs, and artifacts. Prefer paths over pasted content.
- **Fresh context:** receiver starts cold or after a reset. Include enough
  verified state to reconstruct the work without the prior transcript.

## Preserve Target Identity and Authority

Resolve the receiver in this order:

1. Exact model, account, harness, and effort supplied by the user or caller.
2. Exact current model/harness when building a same-session-family restart and
   that identity is known.
3. Model family supplied by the user or caller.
4. Vendor-neutral prompt when neither model nor family is known.

Never silently change a caller-supplied model, account, effort, permission
mode, or security lane. Model references tune prompt shape; they do not reroute
runtime settings. Put unresolved identity in a placeholder instead of guessing.

## Read One Vendor Reference

Read only the reference matching the receiving family:

| Family | Reference |
| --- | --- |
| Anthropic Claude | [references/anthropic.md](references/anthropic.md) |
| OpenAI GPT / Codex | [references/openai.md](references/openai.md) |
| Google Gemini | [references/google.md](references/google.md) |
| xAI Grok / Grok Build | [references/xai.md](references/xai.md) |

### Freshness rule

Verify official vendor documentation before drafting when any condition holds:

- the user asks for the latest, current, newest, best, or recommended model;
- the target version is absent from the matching reference;
- the reference snapshot is more than 30 days old;
- a sibling skill or caller supplies a newer explicit route;
- model availability, IDs, effort levels, or prompting behavior conflict.

Use primary vendor sources. Update the reference snapshot only after verifying
the facts. If live verification is unavailable, preserve the caller's route and
label any model-specific advice as potentially stale.

## Gather Execution-Critical Context

Collect only facts that change the receiver's next action:

- objective and why the outcome matters;
- observable success criteria and completion bar;
- current verified state, baseline, blockers, and open questions;
- files, branches, worktrees, commands, URLs, logs, and artifacts;
- ownership boundaries and areas not to touch;
- authorization, side-effect, and stop boundaries;
- verification commands and expected results;
- output location, report schema, and coordination contract.

Do not paste large logs or history when the receiver can read the artifact.
Distinguish verified facts from assumptions and stale handoff claims.

## Build the Base Handoff

Start with a minimal execution contract. Apply only the model-specific changes
from the selected reference; do not blend guidance from other families.

### Shared-Workspace Handoff

```text
Target: [exact model/account/harness/effort, or known family]
Handoff type: shared workspace

Objective
[One concrete outcome and why it matters]

Success criteria
- [Observable completion condition]
- [Verification condition]

Verified context
- [Current state and relevant facts]

Inputs
- [Paths, branch/worktree, logs, docs, prior outputs]

Ownership and constraints
- Modify: [owned paths]
- Do not touch: [excluded paths]
- Authorization/stop rules: [state-changing or scope boundaries]

Verification
- [Commands or evidence checks]
- [Expected baseline/result]

Output contract
- [Deliverable location or exact response shape]
- [How to report blockers, uncertainty, and incomplete checks]

Coordination
- [Relationship to parallel work and notification contract]
```

### Fresh-Context Handoff

```text
Target: [exact model/harness/effort when known; otherwise family]
Handoff type: fresh context

Project and objective
- Project: [name and one-sentence purpose]
- Outcome: [single concrete outcome and why it matters]
- Start by reading: [entry points]

Verified current state
- Repo/worktree/branch: [paths and refs]
- Completed: [verified work]
- Remaining: [work still required]
- Baseline/blockers: [known failures, risks, assumptions]

Task contract
- Success criteria: [observable completion bar]
- Scope: [owned paths or subsystem]
- Do not change: [explicit exclusions]
- Authorization/stop rules: [side-effect and scope boundaries]

Verification
- Already run: [commands and results]
- Run next: [commands and expected result]

Output contract
- [Deliverable shape and location]
- [How to report mismatches, blockers, TODOs, and uncertainty]
```

Use `[TODO: exact path]` rather than inventing repository facts.

## Apply Model-Specific Tuning

After the base contract exists:

- preserve the selected model and runtime settings exactly;
- restructure to the vendor reference's **Good shape** when it differs;
- add only guidance that changes behavior for this task and target model;
- keep API-only controls outside plain chat prompts unless the handoff is for
  an API harness configuration;
- preserve the orchestrator's transport envelope. For example, a tmux worker's
  worktree setup, commit policy, PM target, and exact DONE line remain intact.

Do not assume every frontier model wants the same ordering. Gemini benefits
from task and critical restrictions at the end; Claude often benefits from XML
separation; GPT‑5.6 favors a lean outcome/evidence/completion contract; Grok
Build benefits from precise paths while loading durable project rules itself.

## Hold the Quality Bar

- Keep a worker task atomic unless the chosen model was explicitly routed for
  long-horizon orchestration.
- Define what done means and what evidence supports it.
- Name files and commands whenever known.
- Preserve exact values, scope words, account boundaries, and stop rules.
- Ask for findings first on review tasks.
- Define source boundaries, freshness, and citations for research.
- Require the receiver to report failed or skipped verification honestly.
- Do not ask for private chain-of-thought; request conclusions, evidence,
  assumptions, checks, and concise reasoning summaries instead.

## Return Format

When asked for a handoff prompt:

1. Return the ready-to-send prompt in one fenced block.
2. List unresolved assumptions or placeholders after the block.
3. Return separate prompts when multiple target models need different tuning.
