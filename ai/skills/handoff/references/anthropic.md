# Anthropic Claude 4.x Handoff Patterns

Source snapshot: refreshed 2026-03-12 from official Anthropic docs

- [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

## Start here

- Be clear and direct. Claude 4.x follows what you ask for, not what you imply.
- State the desired depth, quality bar, and output format explicitly.
- Explain why unusual constraints matter when behavior depends on them.
- Use examples when format or tone must match closely.
- Use XML tags or clearly labeled sections to separate instructions, context, examples, and inputs.

## Handoff emphasis

- Tell Claude whether the task is to implement, suggest, review, or investigate.
- Say whether independent tool calls should be run in parallel.
- Use numbered steps when order matters.
- Point to the files, logs, or state artifacts Claude should read first.
- Keep shared state in files or git artifacts for long-running or multi-session work.

## Good shape

```xml
<context>
[Project slice, current state, relevant files]
</context>

<task>
[Single explicit objective]
</task>

<tool_use>
[Tools to prefer, whether to parallelize]
</tool_use>

<constraints>
[Scope limits and prohibitions]
</constraints>

<verification>
[Checks to run before reporting back]
</verification>

<output>
[Exact return format]
</output>
```

## Examples

- Provide 3 to 5 short examples when you need tight output consistency.
- Keep examples relevant to the actual task.
- Wrap examples in their own section so they do not blur into the instructions.

## Avoid

- vague requests like "be thorough" without defining the deliverable
- burying critical constraints in long prose
- assuming local repo norms are obvious
- mixing stable instructions with mutable project state in the same block
