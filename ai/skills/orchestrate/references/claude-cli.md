# Claude CLI

Current local verification snapshot:

- CLI: `Claude Code 2.1.74`
- verified working:
  - `claude -p ... --permission-mode plan --output-format text`
  - `claude -p ... --permission-mode plan --output-format json --json-schema ...`

Relevant current docs:

- Claude Code CLI reference
- Run Claude Code programmatically
- Claude Code subagents
- Claude Code hooks and settings

## Non-interactive mode

Use `claude -p` for scripted or delegated runs.

Examples:

```bash
claude -p "Summarize this module" --permission-mode plan

claude -p "Return a task map" \
  --permission-mode plan \
  --output-format json \
  --json-schema '{"type":"object","properties":{"tasks":{"type":"array"}},"required":["tasks"],"additionalProperties":false}'
```

## Recommended execution modes

### Read-only planning or research

Use:

```bash
claude -p "$PROMPT" --permission-mode plan
```

Use this for:

- task decomposition
- file discovery
- design comparison
- review and research

### Bounded edit task in current tree

Use:

```bash
claude -p "$PROMPT" --permission-mode acceptEdits
```

Use this when:

- Claude may edit files
- you still want command-side effects guarded

### Normal interactive delegation

Use:

```bash
claude -p "$PROMPT" --permission-mode default
```

Use this when the worker may legitimately need approval decisions during execution.

### Do not default to

- `--dangerously-skip-permissions`
- `--allow-dangerously-skip-permissions`

Only use those in externally sandboxed environments you explicitly control.

## Structured output

Prefer structured output for machine-consumed returns:

- `--output-format json`
- `--json-schema ...`

Use text output when the return artifact is intended for human review.

## Tool shaping

Constrain workers with:

- `--allowedTools`
- `--disallowedTools`
- `--tools`

Best practice:

- use the narrowest tool set that still lets the worker succeed
- do not make “stay read-only” a prompt-only instruction when the CLI can enforce it

## Custom agents and subagents

Claude CLI supports:

- `--agent <agent>`
- `--agents <json>`
- reusable project or user agents under `.claude/agents/`

Use custom agents when a role recurs:

- code-reviewer
- migration-worker
- docs-writer
- test-fixer

Write clear descriptions so Claude knows when to route to them.

## Worktrees

Use `--worktree` when a delegated task needs isolation from the current branch or when multiple implementation tracks may run concurrently.

Relevant flags available locally:

- `--worktree [name]`
- `--tmux`

Good use cases:

- risky refactors
- independent feature spikes
- parallel edit tasks with disjoint ownership

## Session handling

Fresh session by default.

Use:

- `--no-session-persistence` for ephemeral scripted work if you do not want saved session state
- `-c/--continue` only when the same delegated unit genuinely benefits from continuity

## Hooks and settings

When a rule should always apply, move it into Claude infrastructure:

- hooks for deterministic pre/post tool checks
- project settings for team-shared behavior
- local settings for machine-specific overrides

Do not keep re-explaining deterministic rules in every delegated prompt if hooks or settings can enforce them once.
