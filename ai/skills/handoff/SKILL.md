---
name: handoff
description: Generate optimized handoff prompts for delegating work to another LLM agent. Use when handing work to Claude (Fable 5 or the 4.x line incl. Opus 4.8), GPT-5.x/Codex, Gemini 3.x, or Grok 4.x/Grok Build, either as a shared-workspace sub-task handoff or a fresh-context handoff for a new session or model. Triggers on requests like "create a handoff prompt", "delegate this task to another agent", "hand this off", or "prepare context for another agent".
---

# Handoff Prompt Generator

Generate a prompt that another agent can execute without guessing.

## When NOT to Use

- Saving the current session to resume the same work later — use the
  save-session skill.
- Decomposing and running sub-tasks from this session — use the orchestrate
  skill.
- Ongoing supervision of live agents in tmux panes — use the tmux-pm skill
  (handoff covers the one-shot context transfer, not the PM loop).
- The receiving agent is this same conversation continuing; no handoff needed.

## Choose the handoff mode

- Use a shared-workspace handoff when the receiving agent can access the same repo, files, and artifacts.
- Use a fresh-context handoff when the receiving agent starts cold, in another session, or on another platform.
- Ask for the target model family if it is not implied by the user's request. If it still is not known, draft a vendor-neutral base prompt and mark any missing model-specific adjustments.

## Read one model reference

Read only the reference that matches the receiving model:

| Target model family | Reference |
| --- | --- |
| Anthropic Claude (Fable 5 / 4.x line incl. Opus 4.8) | [references/anthropic.md](references/anthropic.md) |
| OpenAI GPT-5.x / Codex | [references/openai.md](references/openai.md) |
| Google Gemini 3.x (3.5 Flash / 3.1 Pro) | [references/google.md](references/google.md) |
| xAI Grok 4.3 / Grok Build | [references/xai.md](references/xai.md) |

If the requested model version is newer than the reference, verify the latest official docs before drafting the handoff.

## Gather only execution-critical context

Collect the minimum information that removes ambiguity:

- objective
- success criteria
- scope boundaries
- relevant files, commands, URLs, or artifacts
- current state and known blockers
- verification steps
- output location or return format
- coordination notes for parallel work

Do not pad the handoff with background that does not change the receiver's next action.

## Build the base handoff

Use flat labeled sections. Prefer direct operational language over narrative explanation.

### Shared-Workspace Handoff

```text
Target model: [family/version]
Handoff type: shared-workspace sub-task

Objective
[One concrete outcome]

Success criteria
- [Observable completion condition]
- [Verification condition]

Context
- [Only facts needed for this slice of work]

Inputs and artifacts
- [file paths, branches, logs, docs, prior outputs]

Ownership
- [files or directories to modify]
- [areas to avoid]

Constraints
- [technical limits]
- [things the agent must not do]

Verification
- [commands, tests, or review checks to run]

Output
- [exact return format]
- [where to write or save artifacts]

Coordination
- [how this work fits with parallel tasks]
```

### Fresh-Context Handoff

```text
Target model: [family/version]
Handoff type: fresh context

Project
- name: [project name]
- overview: [1-2 sentences]
- entry points: [first files or docs to read]

Current state
- completed: [what is already done]
- remaining: [what still needs to be done]
- blockers/baseline: [known failures, risks, or assumptions]

Task
- objective: [single outcome]
- success criteria:
  - [observable condition]
  - [verification condition]

Constraints
- [scope limits]
- [things not to change]
- [environment or policy constraints]

Verification
- [commands, tests, or manual checks]

Output
- [exact deliverable shape]
- [how to report open questions or TODOs]
```

Use placeholders like `[TODO: exact path]` instead of inventing repository facts.

## Apply model-specific tuning

After drafting the base handoff:

- apply the matching reference's adjustments, and restructure to its "Good
  shape" when its section order differs from the base template (Gemini wants
  the task and critical constraints at the end)
- prefer external runtime settings when the receiving harness exposes them
- avoid inventing API-only controls inside plain chat prompts

## Calibrate prescription to the model generation

Current frontier models (Fable 5, GPT-5.5, Gemini 3.x, Grok 4.3) perform best
with shorter, outcome-first handoffs: state the outcome, success criteria,
constraints, and evidence, then let the model choose the path. Anthropic,
OpenAI, and Google explicitly document that process-heavy instruction stacks
written for older models degrade current-model output; xAI's guidance points
the same direction on scope and conciseness. Enumerate steps only when order
genuinely matters or the receiving model is an older generation.

## Hold the quality bar

- Keep the task atomic.
- Define what "done" means.
- Name files and commands whenever possible.
- Reference shared artifacts by path instead of pasting large logs.
- State explicit stop rules for destructive or broad changes.
- Ask for findings first for review tasks.
- Require source boundaries and citation expectations for research tasks.

## Return format

When the user asks for a handoff prompt:

1. Return the ready-to-send prompt in a fenced code block.
2. List assumptions or placeholders after the prompt.
3. Generate separate prompts when the user wants handoffs for multiple models.
