---
description: Generate a self-contained HTML artifact for the current task
argument-hint: "[topic] [--throwaway] [--voice]"
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(rg:*)
---

# /artifact

Generate a single self-contained HTML artifact for the current task. Delegates to the `html-artifacts` skill for the content rules and templates.

Arguments (parsed from `$ARGUMENTS`):

- `[topic]` — kebab-case slug used in the filename. If omitted, derive from the active plan name, the latest issue/PR reference, or a 2–4 word slug of the most recent assistant turn.
- `--throwaway` — write to `docs/.ai/tools/<topic>.html` (interactive editor / scratch tool). Default is `docs/.ai/artifacts/<topic>.html` (durable record).
- `--voice` — after writing the file, invoke the `speak` skill with a ≤100-word summary (routes through the registered `mcp-tts` MCP server). Default is silent.

## Steps

1. **Resolve the topic slug.** If the user passed one, use it after kebab-casing. Otherwise: latest plan filename → latest issue/PR title → 2–4 word summary of current work. Never use timestamps.
2. **Pick the output dir.** `docs/.ai/tools/` if `--throwaway` is present, otherwise `docs/.ai/artifacts/`. Run `mkdir -p` on the chosen directory.
3. **Invoke the `html-artifacts` skill** with the active task content. Follow its "When YES / When NO" gate — if the content doesn't warrant HTML, stop and tell the user; do not produce an HTML wrapper around a short markdown reply.
4. **Write the file** to `<dir>/<topic>.html` following the format rules in `html-artifacts` SKILL.md.
5. **Self-check.** Run the external-resource scan from the skill against the new file and fix any matches.
6. **Voice (only if `--voice`).** Invoke the `speak` skill with a ≤100-word summary of the artifact. Do not call `tts-notify.py` — that's a hook path, not an agent primitive. Without `--voice`, return the spoken-text blurb as plain output so the user can trigger TTS themselves.
7. **Report.** Print the repo-relative path, an `open <path>` command, whether it's durable or throwaway, and the `git add -f <path>` instruction if durable.

## Notes

- `docs/.ai/` is globally gitignored. Durable artifacts need `git add -f` to track.
- This command is Claude-only. In Codex, ask for the `html-artifacts` skill by name or rely on its description-triggered invocation; flags `--throwaway` / `--voice` aren't available there, so state intent in the prompt instead.
- Do not auto-fire this command from other commands or hooks. Keep invocation explicit.
