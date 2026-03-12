# xAI Grok 4.x / Grok Code Handoff Patterns

Source snapshot: refreshed 2026-03-12 from official xAI docs

- [Prompt Engineering for Grok Code](https://docs.x.ai/developers/advanced-api-usage/grok-code-prompt-engineering)
- [Tools overview](https://docs.x.ai/docs/guides/tools/overview)
- [Structured outputs](https://docs.x.ai/docs/guides/structured-outputs)
- [Reasoning](https://docs.x.ai/docs/guides/reasoning)

## Start here

- Provide precise local context such as relevant files, dependencies, and the concrete goal.
- Phrase the task as a clear requirement, not a vague improvement request.
- Keep the scope tight and iterate with follow-up prompts when needed.
- Use structured outputs or tool schemas when the result must be machine-readable.
- Explicitly say when web search, X search, code execution, or function calling is expected.

## Handoff emphasis

- Prefer file-targeted prompts over repo-wide "fix everything" requests.
- Name the exact files or components the model should use as references.
- Ask for concrete output and verification, not general suggestions.
- Remove irrelevant background so the model does not diffuse attention.

## Reasoning and tool notes

- Do not ask for `reasoning_effort` on Grok 4 family models. That control is documented for `grok-3-mini`, not Grok 4.
- Grok supports OpenAI-compatible Responses API patterns plus built-in tools such as web search and code execution.
- Smaller, concrete prompts tend to outperform broad umbrella prompts in coding workflows.

## Good shape

```text
Context
- [Relevant files and constraints]

Objective
[One concrete deliverable]

Required references
- [Files, APIs, or docs to use]

Constraints
- [Scope limits]
- [What not to touch]

Verification
- [Checks to run]

Output
- [Exact return format]
```

## Avoid

- prompts like "make this better"
- irrelevant repository background
- unsupported parameter guidance for Grok 4
- relying on free-form output when a schema is required
