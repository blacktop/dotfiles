# Anthropic Claude Opus 4.5 & Sonnet 4 Handoff Patterns

## Model Characteristics
- Trained for precise instruction following; more steerable than previous generations
- Opus 4.5: Most capable, sensitive to "think" word (use "consider", "evaluate" instead)
- Sonnet 4.5: Aggressive parallel tool execution by default
- Both: Excel at long-horizon reasoning with exceptional state tracking
- Both: Native subagent orchestration capabilities

## Core Prompting Principles

### Be Explicit
Claude 4.x requires explicit instructions. Previous "above and beyond" behavior must now be requested:

```
Less effective: "Create an analytics dashboard"
More effective: "Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation."
```

### Provide Context/Motivation
Explain WHY behind instructions:

```
Less effective: "NEVER use ellipses"
More effective: "Your response will be read aloud by a text-to-speech engine, so never use ellipses since the text-to-speech engine will not know how to pronounce them."
```

### Tool Triggering
Opus 4.5 is more responsive to system prompts. Dial back aggressive language:
- Avoid: "CRITICAL: You MUST use this tool when..."
- Use: "Use this tool when..."

## Fresh Handoff Pattern
For handing off to a fresh agent starting on a project:

```xml
<system>
[Model identity and capabilities]
</system>

<context>
<project_overview>[Brief project description]</project_overview>
<codebase_entry_points>
[Key files to read first]
[Directory structure hints]
</codebase_entry_points>
<current_state>
[What has been completed]
[What remains to be done]
</current_state>
</context>

<task>
[Specific objective]
</task>

<guidance>
<action_mode>[proactive|conservative]</action_mode>
<parallel_execution>[enabled|disabled]</parallel_execution>
<verification_approach>[How to verify correctness]</verification_approach>
</guidance>

<constraints>
[Scope limits]
[What not to do]
</constraints>
```

## Sub-Task/Parallel Handoff Pattern
For delegating to subagents within same project:

```xml
<subagent_task>
<objective>[Specific aspect to handle]</objective>
<output_format>[How findings should be structured]</output_format>
<tool_guidance>[Which resources to prioritize]</tool_guidance>
<task_boundaries>[Scope limits to prevent overlap]</task_boundaries>
<artifact_references>[Lightweight references to shared state]</artifact_references>
</subagent_task>
```

## Multi-Context Window Workflows
Claude 4.5 excels at tasks spanning multiple context windows:

1. **First window**: Set up framework (tests, setup scripts, state files)
2. **Subsequent windows**: Iterate on todo-list

### State Management
```json
// Structured state file (tests.json)
{
  "tests": [
    {"id": 1, "name": "auth_flow", "status": "passing"},
    {"id": 2, "name": "user_mgmt", "status": "failing"}
  ],
  "total": 200, "passing": 150, "failing": 25
}
```

```text
// Progress notes (progress.txt)
Session 3 progress:
- Fixed authentication token validation
- Next: investigate user_management test failures
```

### Starting Fresh Context
Include in fresh context handoff:
```
Call pwd; you can only read and write files in this directory.
Review progress.txt, tests.json, and the git logs.
Manually run through a fundamental integration test before moving on to implementing new features.
```

## Parallel Tool Calling
Enable maximum parallelism with:
```
If you intend to call multiple tools and there are no dependencies between the tool calls, make all of the independent tool calls in parallel. Maximize use of parallel tool calls where possible to increase speed and efficiency.
```

## Key Rules
1. Use XML tags for structure and formatting control
2. Replace "think" with "consider/evaluate/believe" for Opus 4.5
3. Use git for state tracking across sessions
4. Provide verification tools for autonomous work
5. Match prompt style to desired output style
