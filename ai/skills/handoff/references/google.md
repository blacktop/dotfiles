# Google Gemini 3 Pro & Flash Handoff Patterns

## Model Characteristics
- Optimized for temperature=1.0 (do NOT change; may cause looping)
- Knowledge cutoff: January 2025
- 1M token input context, 64k token output
- Less verbose by default; favors direct, efficient answers
- Strong reasoning with explicit thinking levels

## Thinking Levels
Control reasoning depth via `thinking_level` parameter:

| Level | Use Case | Latency |
|-------|----------|---------|
| LOW   | Simple tasks, quick responses | Fastest |
| MEDIUM | Standard reasoning | Moderate |
| HIGH  | Complex analysis, multi-step | Slower |

For LOW latency with silent reasoning: add "think silently" to system instructions.

## Core Prompting Principles

### Be Direct and Precise
Gemini 3 responds best to clear, concise instructions:
- State goals directly
- Avoid unnecessary or persuasive language
- Logic over verbosity

### Use Structured Formatting
XML tags or Markdown distinguish instructions from context:

```xml
<context>
[Background information]
</context>

<task>
[Clear, direct instruction]
</task>

<constraints>
[Restrictions and boundaries]
</constraints>
```

### Anchor Reasoning to Context
Start questions with grounding phrases:
- "Based on the information above..."
- "Using only the provided data..."
- "From the context given..."

## Fresh Handoff Pattern
For handing off to a fresh Gemini agent:

```xml
<system_instructions>
thinking_level: [LOW|MEDIUM|HIGH]
output_style: [concise|detailed|conversational]
</system_instructions>

<project_context>
[Essential project background]
[Key files and structure]
</project_context>

<current_state>
[What has been completed]
[Current progress markers]
</current_state>

<task>
[Direct, clear objective]
</task>

<grounding>
Base all reasoning on the provided context.
Perform calculations strictly on provided data.
Do not introduce external information unless explicitly requested.
</grounding>

<output_format>
[Expected structure and format]
</output_format>
```

## Sub-Task/Parallel Handoff Pattern
For delegating sub-tasks:

```xml
<subtask>
<objective>[Specific goal]</objective>
<thinking_level>[LOW|MEDIUM|HIGH]</thinking_level>
<context_anchor>Based on the above information...</context_anchor>
<scope>[What to include/exclude]</scope>
<output_format>[Expected deliverable format]</output_format>
</subtask>
```

## Leveraging Thinking Capabilities
For complex tasks, prompt structured reasoning:

```
Before providing the final answer, please:
1. Parse the stated goal into distinct sub-tasks.
2. Check if the input information is complete.
3. Create a structured outline to achieve the goal.
```

## Verbosity Control

### Default (Concise)
Model provides direct, efficient answers.

### Conversational Mode
Explicitly request: "Explain this as a friendly, talkative assistant"

### Detailed Mode
"Provide a comprehensive analysis with step-by-step reasoning"

## Search/Grounding Integration
For tasks requiring real-time information:
```
Use Google Search to verify current information before responding.
Ground your response in retrieved sources.
```

## Key Rules
1. Keep temperature at 1.0
2. Use explicit thinking_level for reasoning control
3. Anchor all reasoning to provided context
4. Avoid broad negatives ("do not infer") - be specific
5. Structure prompts: context first, then task, then constraints last
6. Use persona carefully (model may prioritize persona over instructions)
