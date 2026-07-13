# Google Gemini Handoff Patterns

Source snapshot: refreshed 2026-07-12 via Exa from official Google docs.

- [Gemini models](https://ai.google.dev/gemini-api/docs/models)
- [Gemini 3.5 Flash](https://ai.google.dev/gemini-api/docs/whats-new-gemini-3.5)
- [Gemini 3 prompting guide](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/start/gemini-3-prompting-guide)
- [Gemini thinking](https://ai.google.dev/gemini-api/docs/thinking)

## Current lineup for agent handoffs

| Model | Status and best handoff shape |
| --- | --- |
| `gemini-3.5-flash` | Stable; strongest current Flash for agentic execution, coding loops, subagents, and long-horizon work |
| `gemini-3.1-pro-preview` | Preview; advanced intelligence, difficult problem-solving, precise tools, and complex agentic coding |
| `gemini-3.1-flash-lite` | Stable; low-cost, high-volume, bounded extraction, routing, and simple agent tasks |

Preserve the caller's exact model and `thinking_level`. Do not replace a Pro
route with Flash or a stable route with preview based on this reference alone.

## Best results across Gemini 3.x

- Be concise and direct. Verbose prompt-engineering scaffolding from older
  models can cause over-analysis.
- Put large source material first. Put the request and most critical negative,
  formatting, or quantitative constraints at the end.
- For long context, anchor with “Based on the entire document above” and ask
  for synthesis across all relevant portions rather than the first match.
- Define allowed grounding precisely. Prefer “deduce from these sources; do not
  add external facts” over a blanket “do not infer.”
- Use split-step verification when a required source or capability may be
  missing: verify availability first, then act or report `No Info`.
- Gemini is concise by default; request a conversational or expansive style
  only when the deliverable needs it.
- Keep temperature, `top_p`, and `top_k` at defaults. Use explicit instructions
  and schemas for determinism.

## Model-specific tuning

### Gemini 3.5 Flash

- Use `medium` thinking for most complex code and agentic work; `high` for the
  hardest reasoning, math, or coding; `low` for fewer-step low-latency loops;
  `minimal` for simple calls.
- Give it a multi-step outcome, tool and grounding rules, and a concrete
  completion bar. It is designed for sustained rapid agentic loops.
- Preserve the full unmodified interaction history or thought signatures when
  the API harness relies on thought preservation; do not express this as a
  chat-prompt instruction.

### Gemini 3.1 Pro Preview

- Use for the deepest ambiguous reasoning or precise multi-tool execution when
  preview status is acceptable.
- `high` is the default; `minimal` is unsupported. Keep the task and critical
  restrictions at the end even for large contexts.
- If the harness uses a custom-tools endpoint, preserve that exact route.

### Gemini 3.1 Flash-Lite

- Make the task bounded and schema-driven: input set, classification or
  transformation rule, output fields, unknown policy, and stopping condition.
- `minimal` is the default. Increase thinking only when measured accuracy
  requires it; reroute genuinely open-ended work outside the prompt.

## Runtime controls

- Use `thinking_level`: `minimal`, `low`, `medium`, or `high` where supported.
  Do not use it together with legacy `thinking_budget`.
- Do not tune temperature or sampler values for Gemini 3.x by default.
- Match every function response to the preceding call's `id`, `name`, and
  count in an API harness.
- Keep runtime configuration out of a plain Gemini CLI handoff unless the task
  is specifically to configure the harness.

## Good shape

```text
Context and source material
[Verified state, relevant files, documents, logs, and large inputs]

Grounding rules
- [Sources and tools allowed]
- [Deductions allowed and external facts excluded]

Output contract
- [Exact artifact or schema]
- [Evidence, verification, and uncertainty reporting]

Task and critical constraints (last)
[Direct objective and completion bar]
- [Most important scope, negative, formatting, and quantitative limits]
```

## Avoid

- old-model verbose scaffolding or decorative personas;
- silently changing the exact Gemini model, preview/stable choice, or thinking;
- placing critical negative constraints early in a long prompt;
- lowering temperature for determinism;
- broad “do not infer” rules that suppress valid deductions;
- `thinking_budget` on Gemini 3.x;
- requesting private reasoning instead of an evidence-backed result.
