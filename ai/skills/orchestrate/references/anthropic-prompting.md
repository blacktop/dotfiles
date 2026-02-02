# Anthropic Prompting Notes (Claude)

## Role prompting (system prompt)
- Use the system prompt to assign a clear role and keep task-specific instructions in the user message.
- Role prompting improves accuracy, tone alignment, and focus.
- Source: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/system-prompts

## XML tags for structure
- Use XML tags to separate instructions, context, examples, and output format.
- Be consistent with tag names and nest tags for hierarchical content.
- Tags help reduce misinterpretation and improve parseability.
- Source: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/use-xml-tags

## Examples (multishot prompting)
- Provide a few (3-5) diverse, relevant examples for structured outputs or strict formats.
- Wrap examples in <examples> / <example> tags.
- Source: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/multishot-prompting

## Prompt improver takeaways
- Strong templates use XML tags, explicit output format requirements, and example-driven guidance.
- Source: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/prompt-improver

## Chaining prompts
- Break complex tasks into single-goal subtasks.
- Use XML tags to pass outputs between steps and iterate based on performance.
- Source: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/chain-prompts

## Cookbook prompting
- Supplemental prompting patterns and examples.
- Source: https://www.anthropic.com/cookbook/prompting
