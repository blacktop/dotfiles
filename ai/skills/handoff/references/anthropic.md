# Anthropic Claude Handoff Patterns

Source snapshot: refreshed 2026-07-12 via Exa from official Anthropic docs.

- [Models overview](https://platform.claude.com/docs/en/about-claude/models/overview)
- [Prompting Claude Fable 5 and Mythos 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)
- [Prompting Claude Opus 4.8](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-4-8)
- [Prompting Claude Sonnet 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5)
- [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

## Current lineup

| Model | ID | Best handoff shape |
| --- | --- | --- |
| Claude Fable 5 | `claude-fable-5` | Highest generally available capability; hardest ambiguous and long-horizon agents |
| Claude Mythos 5 | `claude-mythos-5` | Limited-access Project Glasswing lane for approved defensive cybersecurity workflows |
| Claude Opus 4.8 | `claude-opus-4-8` | Complex agentic coding, enterprise work, deep review, and security-capable fallback |
| Claude Sonnet 5 | `claude-sonnet-5` | Fast, high-intelligence coding and agentic work |
| Claude Haiku 4.5 | `claude-haiku-4-5-20251001` | Fast, bounded, lower-cost tasks |

Preserve an explicit model, account, harness, and effort. Do not assume Mythos
access or replace Fable/Opus/Sonnet based on this reference alone.

## Best results across current Claude models

- Be clear and direct. State whether the receiver should implement, review,
  investigate, or only advise.
- Define depth, success criteria, scope, output, and verification explicitly.
- Explain why an unusual constraint matters when that context changes the
  model's choices.
- Use XML tags or equally clear labeled blocks to separate instructions,
  context, examples, and variable inputs.
- Use a few positive examples only when format or tone must match tightly.
- For large context, put source documents first and the task after them. Ask
  Claude to ground conclusions in the supplied sources.
- Say whether independent tool calls or subagents should run in parallel.
- Ask for conclusions, evidence, and checks—not a transcript of private
  reasoning.

## Fable 5 and Mythos 5

- Give the hard, end-to-end outcome and reduce legacy prescription. A brief
  steering instruction often outperforms an enumerated behavior list.
- Include intent: who needs the result and what it enables.
- Use `high` effort for most tasks, `xhigh` for capability-critical work, and
  medium/low for routine slices. Preserve an explicit caller setting.
- Expect longer turns. For long runs, define asynchronous progress behavior
  and require every progress claim to point to a tool result from the run.
- State action boundaries: assessment versus implementation, reversible local
  actions versus destructive/external actions, and the real pause conditions.
- Encourage parallel subagents only when the task has independent slices; ask
  the lead to continue useful work while they run.
- For persistent work, name the memory or lesson location and what is worth
  recording; do not ask it to duplicate repo or chat state.

Fable uses safety classifiers for offensive cybersecurity, biology/life
sciences, and reasoning extraction. Benign work may also trigger. Use Opus 4.8
as the explicit fallback when appropriate. Mythos is limited-access and intended
for approved defensive cybersecurity workflows; preserve the caller's access
and policy boundary rather than inferring one.

## Opus 4.8

- Start at `xhigh` for coding and agentic work; `high` is the minimum sensible
  default for most intelligence-sensitive tasks. Test `max` only for the
  hardest workloads because it can overthink.
- Opus is literal. State when a rule applies to every item or section rather
  than expecting silent generalization.
- If tools are important, say which evidence requires them. Higher effort also
  increases tool use.
- Opus tends to spawn fewer subagents; explicitly request parallel delegation
  when the work benefits from it and explicitly avoid it for direct small work.
- Prefer positive examples for response length, tone, and visual direction.

## Sonnet 5

- `high` is the default and fits most work; use `xhigh` for the hardest coding
  and agentic tasks. Preserve caller-selected `max`, medium, or low.
- Adaptive thinking is on by default. Raise effort before adding elaborate
  “think harder” scaffolding.
- Sonnet 5 is more agentic and tool-seeking than Sonnet 4.6, but still state
  why a required search or tool call matters.
- It follows instructions literally, especially at lower effort. State the
  intended scope of formatting, transformations, or repeated operations.
- Use explicit visual direction instead of generic negative design prompts.

## Haiku 4.5

Give one bounded task, the relevant inputs, an exact output schema, and a short
verification rule. Do not compensate for model fit with a long process prompt.

## Runtime controls

- Keep model IDs, effort, thinking, and output-token controls in the harness.
- Fable/Mythos use adaptive thinking only. Sonnet 5 enables adaptive thinking
  by default; Opus 4.8 supports it but API callers must enable it explicitly.
  Manual `budget_tokens` guidance from older models does not apply to these
  current handoffs.
- Do not put unsupported sampling parameters into a Sonnet 5 handoff.
- Query the Models API or current CLI help when exact capabilities matter.

## Good shape

```xml
<context>
[Why the work matters; verified current state; relevant files and evidence]
</context>

<task>
[One explicit outcome with observable success criteria]
</task>

<tool_use>
[Required tools, evidence rules, and parallel/delegation guidance]
</tool_use>

<constraints>
[Scope, authority, side-effect boundaries, and stop conditions]
</constraints>

<verification>
[Checks to run and evidence required before claiming progress or completion]
</verification>

<output>
[Exact deliverable or report shape]
</output>
```

## Avoid

- old-model instruction stacks that restate reliable default behavior;
- changing a caller-selected Claude model or effort;
- asking Fable/Mythos to show, echo, transcribe, or explain private reasoning;
- offensive-cyber work routed to Fable despite its classifier boundary;
- vague “be thorough” or “make it better” requests without a completion bar;
- critical constraints buried in undifferentiated prose;
- mixing stable instructions and mutable project state in one dense block.
