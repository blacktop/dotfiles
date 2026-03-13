# Codex

Current best-practice fit:

- Repo-local skill is the right abstraction.
- Codex docs emphasize durable repo guidance, repeatable workflows, verification, and skills over one-off prompts.

Relevant current docs:

- Codex best practices
- Codex prompting guide
- Agent skills docs

## Recommended usage

Invoke the skill after finishing a coding pass and before finalizing. Unless the user says review-only, the skill should fix clear, local issues it finds and rerun a narrow verification step.

Codex-specific best practices to preserve:

- keep prompts small and explicit
- define the output contract
- include verification
- treat repeated workflow knowledge as a skill, not a copied prompt

## Practical use

Typical invocation:

```text
Use $are-you-sure to re-review the changes you just made with fresh eyes.
```

Pair it with:

- the diff scope
- verification commands already run
- whether fixes are allowed or review-only

## Why skill over agent

Use a skill by default because the behavior is a repeatable workflow that should auto-activate or be invoked explicitly. Create a separate agent only if you want a permanently distinct reviewer persona with its own model, tools, or autonomy settings.
