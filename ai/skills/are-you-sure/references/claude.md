# Claude Code

Current best-practice fit:

- Make this a real skill, not only a command.
- Claude Code's docs say custom commands have merged into skills.
- A file at `.claude/commands/are-you-sure.md` can keep working, but `.claude/skills/are-you-sure/SKILL.md` is the better long-term home.

Relevant current docs:

- Extend Claude with skills
- Claude Code best practices
- Claude prompt engineering best practices

## Recommended usage

Use this skill after a coding pass and before final handoff. Unless the user says review-only, Claude should fix clear local issues it finds and rerun a narrow verification step.

Claude-specific best practices to preserve:

- be clear and direct
- give Claude a way to verify its work
- keep output format explicit
- keep context concise

## Programmatic invocation

For a scripted fresh-eyes pass, `claude -p` works well.

Examples:

```bash
claude -p "/are-you-sure" --permission-mode default --output-format text
```

For structured findings:

```bash
claude -p "/are-you-sure" \
  --permission-mode default \
  --output-format json \
  --json-schema '{"type":"object","properties":{"findings":{"type":"array"}},"required":["findings"],"additionalProperties":false}'
```

Use `--permission-mode plan` only when you explicitly want review-only behavior.

## Why skill over agent

Use a skill by default because this behavior is a reusable workflow, not a persistent specialist persona. Create a subagent only if you later want a dedicated, always-available reviewer role with custom tools and permissions.
