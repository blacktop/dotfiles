# Google Gemini 3.x Handoff Patterns

Source snapshot: refreshed 2026-06-12 from official Google docs

- [What's new in Gemini 3.5 Flash](https://ai.google.dev/gemini-api/docs/whats-new-gemini-3.5)
- [Gemini 3 prompting guide](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/start/gemini-3-prompting-guide)
- [Thinking levels](https://ai.google.dev/gemini-api/docs/thinking)

## Model lineup

- **Gemini 3.5 Flash**: frontier intelligence at speed; built for agentic
  loops and subagent deployment; `thinking_level` default `medium`.
- **Gemini 3.1 Pro**: deepest reasoning; `thinking_level` default `high`
  (dynamic); does not support `minimal` and thinking cannot be disabled.

## Start here

- Be concise and direct. Gemini 3.x responds best to clear, minimal
  instructions; verbose prompt-engineering scaffolding written for older
  models causes over-analysis.
- Put the core request and the most critical restrictions at the END of the
  prompt — negative constraints stated early get dropped in complex prompts.
- For large contexts (whole files, logs, datasets), place instructions after
  the data and anchor with "Based on the entire document above...".
- Gemini 3.x is less verbose by default; steer explicitly if a chattier or
  more conversational deliverable is wanted.
- Keep temperature at the default `1.0`; lowering it degrades reasoning and
  can cause looping.

## Reasoning controls

If the receiving harness exposes Gemini settings, use `thinking_level`
(`thinking_budget` is the legacy 2.5-era control):

- `minimal` — speed-critical chat or simple tool calls (not on 3.1 Pro)
- `low` — short-step agentic/code tasks; much improved in 3.5 Flash
- `medium` — recommended default for complex code and agentic work
- `high` — hardest reasoning and multi-step problems; slower first token
- add "think silently" only when latency matters and the answer can be terse

## Grounding rules

- Prefer explicit grounding such as "Use only the repository state and notes
  below for deductions."
- Avoid broad negatives like "do not infer" — they suppress normal synthesis;
  state what sources and deductions are allowed instead.
- Say whether search grounding or other retrieval is allowed when current
  information matters.

## Good shape

```text
Context
[Essential background, artifacts, large data first]

Grounding rules
- [What sources may be used]
- [What deductions are allowed]

Output
- [Exact structure]
- [Verification or citations required]

Task (last, with critical constraints)
[Direct objective]
- [Most critical restrictions, stated here at the end]
```

## Avoid

- verbose scaffolding and over-styled personas (over-analysis risk)
- critical or negative constraints buried early in a long prompt
- lowering temperature by default
- broad negatives instead of specific grounding rules
- `thinking_budget` on 3.x models — use `thinking_level`
