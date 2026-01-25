# OpenAI GPT-5.2 & GPT-5.2-Codex Handoff Patterns

## Model Characteristics
- Trained for precise instruction following; ambiguity is a bug
- Supports `reasoning_effort` parameter: minimal, low, medium, high, xhigh
- Best-in-class for agentic coding with multi-hour autonomous operation
- Uses AGENTS.md format for persistent instructions

## CTCO Framework (Required Structure)
Structure all prompts using Context → Task → Constraints → Output:

```
<context>
[Who is the model? Background state? Project context?]
</context>

<task>
[Single, atomic action required]
</task>

<constraints>
[Negative constraints - what NOT to do]
[Scope limits]
</constraints>

<output>
[Expected format, structure, deliverables]
</output>
```

## Reasoning Effort Control

### Low/Minimal Effort
- Best for: migrations, formatting, data extraction
- Prompt key: "Directly output the result without preamble."

### High Effort
- Best for: coding refactors, complex logic, debugging
- Prompt key: "Plan the solution step-by-step. Verify the logic of step 2 before proceeding to step 3."

## AGENTS.md Format for Fresh Handoffs
When handing off to a fresh agent, structure as AGENTS.md:

```markdown
# Project: [Name]

## Working Agreements
- [Testing requirements]
- [Code style expectations]
- [Review standards]

## Repository Expectations
- [Build commands]
- [Linting rules]
- [Documentation standards]

## Current Task
[Specific objective with success criteria]

## Context
[Essential background - keep minimal]

## Constraints
[What not to do]
[Scope limits]
```

## Sub-Task Handoff Pattern
For parallel/sub-task handoffs, use Plan-then-Execute:

```xml
<planning>
[Strategic analysis of the task]
[Decomposition into sub-steps]
</planning>

<task_handoff>
<objective>[Specific goal]</objective>
<reasoning_effort>[minimal|low|medium|high]</reasoning_effort>
<context>[Only what's needed for this specific task]</context>
<constraints>[Scope limits, what not to do]</constraints>
<expected_output>[Format and deliverables]</expected_output>
<dependencies>[Files, APIs, or artifacts needed]</dependencies>
</task_handoff>
```

## Key Prompting Rules
1. Use XML-tagged scaffolding for structure
2. Separate constraints from task (reduces instruction drift)
3. Use strict JSON schemas for structured output
4. Include negative constraints explicitly ("Do not...")
5. Keep prompts architectural, not conversational
