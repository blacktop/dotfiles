# xAI Grok 4.5 / Grok Build Handoff Patterns

Source snapshot: refreshed 2026-07-12 via Exa from official xAI docs.

- [Grok 4.5](https://docs.x.ai/developers/grok-4-5)
- [Reasoning controls](https://docs.x.ai/developers/model-capabilities/text/reasoning)
- [Grok Build](https://docs.x.ai/build/overview)
- [Grok Build project rules](https://docs.x.ai/build/features/project-rules)
- [Tools overview](https://docs.x.ai/developers/tools/overview)

## Current lineup for handoffs

- **`grok-4.5`** is xAI's current frontier model for coding, agentic tasks,
  and knowledge work. It is also the default model powering Grok Build.
- Grok Build can run interactively, headlessly, or through ACP. Preserve the
  caller's chosen surface, model, effort, worktree, permissions, and session.
- Specialized or legacy model IDs should be used only when the caller supplies
  them or current official docs are checked; do not infer a multi-agent route
  from task size alone.

## Best results

- State one concrete requirement, relevant local context, exact files or
  components, scope boundaries, and a verification command.
- Prefer a narrow file-targeted handoff over a repo-wide “fix everything”
  prompt. Remove background that does not change the next action.
- In Grok Build, rely on repo `AGENTS.md` and nested project rules for durable
  conventions. Do not duplicate the full ruleset in every handoff.
- Explicitly say when web search, X search, code execution, or custom function
  calling is expected and what evidence ends the search.
- Ask for concrete edits, checks, and return fields rather than general advice.
- Use structured output or strict tool schemas when another system parses the
  result.
- For long agent loops, preserve stable conversation state and compact at
  meaningful milestones in the harness rather than pasting transcript history.

## Reasoning and runtime

`grok-4.5` reasoning cannot be disabled:

| Effort | Best fit |
| --- | --- |
| `low` | Latency-sensitive agentic work and simple tool calls |
| `medium` | Complex analysis and long-context reasoning |
| `high` (default) | Hard multi-step logic, coding, math, and quality-first work |

Preserve a caller-selected effort. Runtime-only controls belong in the
harness:

- Use `prompt_cache_key` with the Responses API or `x-grok-conv-id` with Chat
  Completions for stable conversation routing and caching.
- Do not send presence/frequency penalties or stop sequences to Grok 4.5
  reasoning requests.
- Process parallel function calls together and return matching tool results.
- Do not paste cache, API, or sampler controls into a normal Grok Build prompt.

## Good shape

```text
Target
[Exact Grok model/surface/effort supplied by the caller]

Objective
[One concrete deliverable]

Context and required references
- [Exact files, branch/worktree, current behavior, logs, APIs]

Tools expected
- [Search, code execution, function calls, or none]
- [Evidence and stopping rule]

Constraints
- [Owned scope, exclusions, permissions, and stop conditions]

Verification
- [Commands and expected result]

Output
- [Artifact path or exact report/schema]
```

## Avoid

- stale Grok 4.3 or Grok Build 0.1 defaults when the target is current;
- silently changing the model, effort, surface, permissions, or worktree;
- vague prompts such as “make this better”;
- duplicating long `AGENTS.md` rules already loaded by Grok Build;
- irrelevant repository history;
- unsupported sampler penalties or stop sequences;
- free-form output when a downstream system requires a schema;
- asking for private chain-of-thought instead of conclusions and evidence.
