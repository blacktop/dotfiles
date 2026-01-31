---
name: save-session
description: |
  Save AI agent session information for later resumption. Use when:
  (1) Finishing a work session and want to save progress
  (2) User says "save session", "remember this session", or "save your session ID"
  (3) Before ending a long coding/debugging session
  (4) When user wants to be able to resume this conversation later
  Supports Claude, Codex, Gemini, Copilot, Cursor, and other AI agents.
---

# Save Session

Save session metadata to `docs/.ai/sessions.json` for future resumption by any AI agent.

## Usage

```bash
python3 ~/.claude/skills/save-session/scripts/save_session.py \
  --session-id "SESSION_ID" \
  --agent "claude" \
  --summary "Brief description of work done" \
  --repo-root "$(pwd)"
```

## Finding Your Session ID by Agent

### Claude Code

**Session storage:** `~/.claude/projects/<project-hash>/<SESSION_ID>.jsonl`

**How to find:**
- Extract UUID from file paths in context (e.g., tool output paths contain the session ID)
- Use `/status` command to see session info
- List sessions: `claude --resume` (interactive picker)

**Environment:** `CLAUDE_CONFIG_DIR` changes storage location (default: `~/.claude`)

**Resume:** `claude --resume SESSION_ID` or `claude -r SESSION_ID`

### OpenAI Codex CLI

**Session storage:** `~/.codex/sessions/`

**How to find:**
- Use `/status` command within Codex
- Copy from session picker
- List files in `~/.codex/sessions/`

**Note:** Session ID is not currently exposed to the model itself (see GitHub issue #5912)

**Resume:** `codex resume SESSION_ID`

### Google Gemini CLI

**Session storage:** `~/.gemini/tmp/<project_hash>/chats/`

**How to find:**
- Use `gemini --list-sessions` to see all sessions with UUIDs
- Sessions are project-specific

**Resume options:**
- `gemini --resume` (latest session)
- `gemini --resume <UUID>` (specific session)
- `gemini --resume <index>` (by index number)
- `/resume` command within interactive mode

### GitHub Copilot CLI

**How to find:**
- Use `/session` or `/usage` command to display current session ID
- Use `gh agent-task list` (requires gh v2.80.0+)
- Use `gh agent-task view` for session details

**Resume:** `/resume SESSION_ID` or `/resume last`

**Note:** Auto-compaction maintains context across long sessions

### Cursor IDE

**Session storage:** SQLite databases in workspace storage
- **macOS:** `~/Library/Application Support/Cursor/User/workspaceStorage/`
- **Linux:** `~/.config/Cursor/User/workspaceStorage/`
- **Windows:** `%APPDATA%\Cursor\User\workspaceStorage\`

**How to find:** Sessions stored in `.vscdb` files as JSON blobs

**Note:** No built-in session ID. Use SpecStory extension for backup/export.

### Aider

**Session storage:** Chat history in `.aider.chat.history.md` in repo root

**Note:** No formal session ID system. History is file-based and can be referenced by timestamp.

## Session File Format

```json
{
  "sessions": [
    {
      "id": "uuid-session-id",
      "agent": "claude",
      "summary": "Implemented multi-platform CI",
      "created_at": "2026-01-31T15:45:00Z",
      "tags": ["ci", "rust"]
    }
  ]
}
```

## Resuming Sessions

| Agent | Resume Command |
|-------|----------------|
| Claude Code | `claude --resume SESSION_ID` |
| Codex | `codex resume SESSION_ID` |
| Gemini CLI | `gemini --resume SESSION_ID` |
| Copilot CLI | `/resume SESSION_ID` |
| Cursor | Restore from workspaceStorage backup |
| Aider | Reference `.aider.chat.history.md` |
