# Context Management Patterns

Read this only when revising `high-tide` or explaining its design.

## External Patterns From Exa Research

- Anthropic's context-engineering cookbook separates compaction, tool-result clearing, and memory. The useful lesson for `high-tide`: compaction is lossy, while durable notes preserve knowledge across resets. Source: https://platform.claude.com/cookbook/tool-use-context-engineering-context-engineering-tools
- Blink's Claude Code context-management guide recommends `/clear` for a clean restart when context is noisy, with a short user-controlled brief as the first message after the reset. Source: https://blink.new/blog/claude-code-context-management
- `claude-code-handoff` uses a handoff -> `/clear` -> resume loop and an auto-handoff threshold so the agent captures state before the context window is exhausted. Source: https://github.com/eximIA-Ventures/claude-code-handoff
- The Agentic Coding Patterns handoff writeup frames handoffs as curated transfer artifacts, not transcript dumps. It emphasizes objective, constraints, prior decisions, current state, and next steps. Source: https://aipatternbook.com/handoff
- Claude Code status-line scripts receive JSON on stdin. The measured context field is `context_window.used_percentage`; related token fields live under `context_window`. This repo's `ai/claude/statusline.sh` uses that exact field to render `ctx:<pct>%`. Source: https://code.claude.com/docs/en/statusline
- Claude Code context usage is not currently exposed as a normal hook environment variable. Open issues request env vars such as `CLAUDE_CONTEXT_PERCENT`; existing env vars configure behavior rather than reporting current usage. Source: https://github.com/anthropics/claude-code/issues/34340
- Codex CLI documents `/status` for session configuration, token usage, and remaining context capacity. `/statusline` configures footer items including context stats. Source: https://developers.openai.com/codex/cli/slash-commands
- Codex docs show `tui.status_line` defaults include `context-remaining`, which is a persistent footer surface rather than an environment variable. Source: https://developers.openai.com/codex/config-sample

## Design Rules

- Capture before degradation is severe.
- Prefer curated facts over full chat history.
- Preserve rejected hypotheses and why they were rejected.
- Make the next action concrete enough that a fresh agent can start without rediscovery.
- Keep durable notes local to the active task unless the user explicitly asks for long-term memory updates.
- Treat context percentage as measured data only. Status-line stdin JSON is measured data; ordinary shell env vars are not. If no measured surface is available, record `unknown` and never claim a guessed threshold.
- Use `scripts/context_percent.py` to normalize measured payloads or status snippets into a used percentage. In this dotfiles setup, Claude's statusline writes minimal fresh telemetry to `${CLAUDE_CONFIG_DIR:-~/.claude}/statusline/context.json`, and the helper reads that automatically when no stdin/file/input is provided. The helper should reject unrelated percentages such as rate-limit usage and convert explicit remaining-context values into used-context values.
- Treat sub-agents and external workflows as a narrow pressure valve, not a reason to keep filling the parent context: they are useful only when they receive their own compact prompt and return compact results or artifact paths.
- Split session continuity from project learning: handoffs keep the next agent moving, while durable repo lessons belong in the most specific `docs/.ai/lessons/` directory that owns the fact.
