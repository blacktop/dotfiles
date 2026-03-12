# OpenAI GPT-5.x / Codex Handoff Patterns

Source snapshot: refreshed 2026-03-12 from official OpenAI docs

- [Prompt guidance for GPT-5.4](https://developers.openai.com/api/docs/guides/prompt-guidance/)
- [Using GPT-5.4](https://developers.openai.com/api/docs/guides/latest-model/)
- [GPT-5 prompting guide](https://developers.openai.com/cookbook/examples/gpt-5/gpt-5_prompting_guide/)
- [GPT-5.2 prompting guide](https://developers.openai.com/cookbook/examples/gpt-5/gpt-5-2_prompting_guide/)

## Start here

- Prefer the Responses API or an agent wrapper that preserves tool state across turns.
- State the objective, tool-use rules, completion criteria, verification plan, and output contract explicitly.
- Use labeled blocks or clearly separated sections so the model can keep context, constraints, and deliverables distinct.
- Ask for structured outputs or strict schemas when another system will parse the result.
- Tell the agent whether to act proactively or stop after analysis.

## Handoff emphasis

- Name the tools or files the agent should use first.
- Separate scope boundaries from background context.
- Give concrete stop rules for destructive, broad, or expensive actions.
- Include exact verification commands when correctness matters.
- Prefer direct operational language over conversational setup.

## Runtime knobs

If the receiving harness exposes model settings, prefer these there instead of spelling them out in prose:

- `reasoning.effort`: use `none` or `low` for extraction, classification, and formatting; use `medium` or `high` for debugging, coding, and multi-step planning.
- `text.verbosity`: use `low`, `medium`, or `high` to control response length without rewriting the whole prompt.
- structured outputs or strict tool schemas: use them whenever machine-readable output is required.

## Good shape

```text
Context
[Only facts the agent needs]

Task
[Single concrete outcome]

Tool use
- [Which tools/files to use]
- [Whether to act proactively]

Constraints
- [Scope limits]
- [What not to change]

Verification
- [Checks to run]

Output contract
- [Exact format to return]
- [Artifacts to write]
```

## Avoid

- vague goals like "improve this"
- hidden completion criteria
- mixing examples, constraints, and background in one paragraph
- relying only on broad negative instructions when a positive target behavior can be stated
- asking for internal reasoning when a final answer, checklist, or evidence summary is enough
