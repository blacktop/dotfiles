# Gemini CLI

Current best-practice fit:

- Gemini CLI supports first-class agent skills via `gemini skills`.
- The skill should stay provider-neutral, with Gemini-specific installation and prompting notes here.

Verified local surface:

```bash
gemini skills --help
```

shows:

- `gemini skills list`
- `gemini skills install`
- `gemini skills link`
- `gemini skills enable`
- `gemini skills disable`

Relevant current docs:

- Gemini prompt design strategies
- Gemini 3 model guidance

## Recommended usage

Link or install the skill, then invoke it through normal Gemini prompting flow. Unless the user says review-only, the skill should fix clear, local issues it finds and rerun a narrow verification step.

Gemini-specific best practices to preserve:

- keep instructions clear and specific
- define the exact output structure
- iterate prompt wording if the review comes back too vague
- if pinning a model, use `gemini-3.1-pro-preview`; Gemini 3 Pro Preview was shut down on 2026-03-09

## Suggested installation paths

For a local linked skill:

```bash
gemini skills link /path/to/are-you-sure
```

For a reusable installed skill:

```bash
gemini skills install /path/to/are-you-sure
```

## Why skill over agent

Use a skill by default because this is a short review workflow, not a long-lived specialist with separate permissions or tooling. If you later want a dedicated Gemini reviewer with custom MCP or extension behavior, wrap this skill with that agent rather than duplicating the workflow.
