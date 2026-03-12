# Google Gemini 3.x Handoff Patterns

Source snapshot: refreshed 2026-03-12 from official Google docs

- [Prompt design strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies)
- [Gemini 3 prompting guide](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/start/gemini-3-prompting-guide)
- [Overview of prompting strategies](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/prompt-design-strategies)

## Start here

- Give clear and specific instructions.
- Use prefixes or XML-style delimiters for complex prompts.
- Keep persona light so task instructions stay dominant.
- Anchor the task to the provided repo state, files, or source material when external knowledge should not be used.
- Keep temperature at the default `1.0` for Gemini 3 models unless you have measured evidence that another setting helps.

## Reasoning controls

If the receiving harness exposes Gemini reasoning settings:

- use `thinking_level=LOW` for low-latency, straightforward work
- use `thinking_level=MEDIUM` for standard coding and analysis
- use `thinking_level=HIGH` for harder multi-step tasks
- add "think silently" only when you need lower-latency reasoning with a terse final answer

## Grounding rules

- Prefer explicit grounding instructions such as "Use only the repository state and notes below for deductions."
- Avoid broad negatives like "do not infer." They can suppress normal calculations and synthesis.
- Tell Gemini when search grounding or other retrieval is allowed if current information matters.

## Good shape

```text
Context
[Essential background and artifacts]

Task
[Direct objective]

Grounding rules
- [What sources may be used]
- [What deductions are allowed]

Constraints
- [Scope limits]
- [Things to avoid]

Output
- [Exact structure]
- [Verification or citations required]
```

## Avoid

- lowering temperature by default
- broad negatives instead of specific grounding rules
- over-styled personas that compete with the task
- hiding the required format inside long context paragraphs
