# xAI Grok Handoff Patterns (Grok 4.3 / Grok Build)

Source snapshot: refreshed 2026-06-12 from official xAI docs

- [Models overview](https://docs.x.ai/developers/models)
- [Reasoning](https://docs.x.ai/developers/model-capabilities/text/reasoning)
- [Grok Build](https://docs.x.ai/build/overview)

## Model lineup

- **Grok 4.3**: flagship for chat and coding; 1M context; supports
  `reasoning_effort` none/`low` (default)/medium/high.
- **grok-build-0.1**: the coding-agent model behind the Grok Build CLI
  (interactive TUI, headless `grok -p`, or ACP integration).
- **grok-4.20-multi-agent**: `reasoning.effort` controls how many agents
  collaborate (4 or 16), not reasoning depth — a deep-research lane, not a
  coding lane.

## Start here

- Provide precise local context: relevant files, dependencies, and the
  concrete goal; phrase the task as a clear requirement.
- Keep the scope tight and iterate with follow-up prompts when needed.
- Use structured outputs or tool schemas when the result must be
  machine-readable.
- Explicitly say when web search, X search, code execution, or function
  calling is expected.

## Handoff emphasis

- Prefer file-targeted prompts over repo-wide "fix everything" requests;
  smaller concrete prompts outperform umbrella prompts in coding workflows.
- Name the exact files or components the model should use as references.
- Ask for concrete output and verification, not general suggestions.
- Remove irrelevant background so the model does not diffuse attention.

## Runtime knobs

- `reasoning_effort` on Grok 4.3: defaults to `low` (good for general agentic
  and tool-calling work); `medium` for complex analysis and long-context
  reasoning; `high` for the hardest multi-step problems; `none` disables
  thinking for near-instant replies.
- Do not send `presence_penalty`, `frequency_penalty`, or `stop` to reasoning
  models — the request errors. `logprobs` is silently ignored on 4.20+.
- Reasoning is exposed only as summaries (or encrypted content for replay);
  do not ask the model to transcribe its full reasoning.
- Grok supports OpenAI-compatible Responses API patterns plus built-in tools
  (web search, code execution).

## Good shape

```text
Context
- [Relevant files and constraints]

Objective
[One concrete deliverable]

Required references
- [Files, APIs, or docs to use]

Tools expected
- [search / code execution / function calling, if any]

Constraints
- [Scope limits]
- [What not to touch]

Verification
- [Checks to run]

Output
- [Exact return format or schema]
```

## Avoid

- prompts like "make this better"
- irrelevant repository background
- sampler penalties or `stop` sequences on reasoning models
- relying on free-form output when a schema is required
- confusing the multi-agent model's effort (agent count) with reasoning depth
