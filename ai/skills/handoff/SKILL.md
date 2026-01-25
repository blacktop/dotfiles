---
name: handoff
description: Generate optimized handoff prompts for delegating tasks to LLM agents. Use when needing to hand off work to another agent (GPT-5.2/Codex, Claude Opus 4.5/Sonnet 4, or Gemini 3 Pro/Flash), whether for a sub-task/parallel task within the same project or a fresh start handoff to a new agent context. Triggers on requests like "create a handoff prompt", "delegate this task to another agent", "hand this off", or "prepare context for another agent".
---

# Handoff Prompt Generator

Generate optimized handoff prompts for different LLM agents and handoff types.

## Handoff Types

### 1. Sub-Task/Parallel Handoff
For delegating a portion of work to another agent within the same project:
- Agent has access to same codebase/files
- Shared context exists
- Task is scoped subset of larger work
- May run in parallel with other agents

### 2. Fresh Start Handoff
For handing off to an agent starting with a new context:
- Agent starts with no prior context
- Needs project orientation
- Requires state files and entry points
- May be a new session or different model

## Workflow

1. **Identify target model** - Ask which model family will receive the handoff
2. **Identify handoff type** - Sub-task/parallel or fresh start
3. **Gather context** - Collect essential information for the handoff
4. **Generate prompt** - Apply model-specific patterns from references
5. **Review and refine** - Ensure prompt is complete and well-scoped

## Model-Specific References

Read the appropriate reference based on target model:

| Target Model | Reference File |
|-------------|----------------|
| GPT-5.2, GPT-5.2-Codex | [references/openai.md](references/openai.md) |
| Claude Opus 4.5, Sonnet 4 | [references/anthropic.md](references/anthropic.md) |
| Gemini 3 Pro, Gemini 3 Flash | [references/google.md](references/google.md) |

## Universal Handoff Components

Every handoff prompt should include:

### Required
- **Objective**: Clear, specific goal
- **Scope/Boundaries**: What is and isn't in scope
- **Output Format**: Expected deliverable structure
- **Constraints**: What not to do, limitations

### For Fresh Start Handoffs (add these)
- **Project Context**: Essential background
- **Entry Points**: Key files to read first
- **Current State**: What's done, what remains
- **State Files**: Progress tracking files to check

### For Sub-Task Handoffs (add these)
- **Dependencies**: Files, APIs, or prior outputs needed
- **Artifact References**: Shared state or outputs
- **Coordination Notes**: How this task fits with parallel work

## Quick Templates

### Sub-Task Handoff (Universal)
```xml
<task_handoff target="[MODEL]">
<objective>[Specific, atomic goal]</objective>
<context>[Only what's needed for THIS task]</context>
<dependencies>[Files, APIs, prior outputs needed]</dependencies>
<scope>
  <include>[What to do]</include>
  <exclude>[What NOT to do]</exclude>
</scope>
<output>
  <format>[Structure of deliverable]</format>
  <location>[Where to save/return results]</location>
</output>
<coordination>[How this fits with parallel work]</coordination>
</task_handoff>
```

### Fresh Start Handoff (Universal)
```xml
<fresh_context target="[MODEL]">
<project>
  <name>[Project name]</name>
  <overview>[1-2 sentence description]</overview>
  <entry_points>[Key files to read first]</entry_points>
</project>
<state>
  <completed>[What's done]</completed>
  <remaining>[What needs to be done]</remaining>
  <state_files>[progress.txt, tests.json, etc.]</state_files>
</state>
<task>
  <objective>[Specific goal]</objective>
  <success_criteria>[How to verify completion]</success_criteria>
</task>
<constraints>
  [Scope limits]
  [What not to do]
</constraints>
<output>
  <format>[Expected structure]</format>
  <verification>[How to validate results]</verification>
</output>
</fresh_context>
```

## Model-Specific Adjustments

After generating the base prompt, apply these adjustments:

### GPT-5.2/Codex
- Use CTCO framework (Context → Task → Constraints → Output)
- Add `<reasoning_effort>` tag (minimal/low/medium/high)
- For fresh handoffs, format as AGENTS.md

### Claude Opus 4.5/Sonnet 4
- Avoid word "think" for Opus 4.5 (use consider/evaluate)
- Add explicit action mode (proactive vs conservative)
- Include parallel execution guidance
- Reference git for state tracking

### Gemini 3 Pro/Flash
- Add `thinking_level` (LOW/MEDIUM/HIGH)
- Include anchoring phrase ("Based on the above...")
- Avoid broad negatives; be specific
- Note: keep temperature at 1.0

## Best Practices

1. **Minimize context** - Include only what's essential for the task
2. **Be explicit** - State goals clearly; don't rely on inference
3. **Scope tightly** - Prevent overlap with parallel tasks
4. **Include verification** - How will the agent know it succeeded?
5. **Reference artifacts** - Point to shared state rather than duplicating
6. **Match model style** - Use patterns the target model responds to best
