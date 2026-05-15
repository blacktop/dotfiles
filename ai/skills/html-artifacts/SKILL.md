---
name: html-artifacts
description: Produce a single self-contained .html artifact (no build, no external assets) when the task is spatial, interactive, visual, multi-axis, or long-running. Triggers on "build me an HTML for X", "make a dashboard / status snapshot / comparison / decision tree / timeline / architecture map", "render this plan as a clickable site", or when content can't fit markdown structurally. Skips short replies, code-only outputs, simple plans.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash(mkdir:*)
  - Bash(rg:*)
---

# HTML Artifacts

Emit a single self-contained `.html` file when markdown can't carry the content. Default everywhere else stays markdown.

## When YES

Use HTML for outputs where structure or interactivity is load-bearing:

- **Comparisons** with ≥3 axes (options × criteria × tradeoffs) that benefit from sortable / filterable tables.
- **Complex plans** that need navigation, a decision surface, or a clickable map. Simple linear plans stay markdown.
- **Code reviews** with annotated diffs, module maps, or call/data-flow graphs.
- **Visual explanations** where a timeline, process flow, architecture/system map, ERD-style relationship view, concept map, or infographic makes relationships clearer than prose.
- **Long-work status snapshots** with exact counts, validation matrices, decision logs, and "what's next" surfaces. See `references/status-snapshot.md`.
- **Throwaway tools** (interactive editors) — drag-drop, sliders, live filters — where the user manipulates inputs and exports a decision. See `references/interactive-editor.md`.
- **SVG-flow explainers** where ASCII or markdown lists lose the spatial relationship.

## When NO

Stay in markdown for:

- Short answers, terminal-style replies.
- Code-only outputs (return the code block; don't wrap it in HTML).
- Simple plans with linear steps and no decisions to navigate.
- Prose summaries that already fit cleanly in a few paragraphs.
- Anything where the user asked for markdown specifically.

If you're unsure, default to markdown.

## Output paths

The repo's global ignore (`**/docs/.ai/`) keeps these directories out of git unless force-added.

| Intent | Path | Tracking |
| --- | --- | --- |
| Durable record | `docs/.ai/artifacts/<slug>.html` | Ignored. Tell user to `git add -f <path>` if they want it tracked. |
| Throwaway tool | `docs/.ai/tools/<slug>.html` | Ignored. Export decisions back to markdown or a task list, then discard. |

Create the parent directory if missing:

```fish
mkdir -p docs/.ai/artifacts   # or docs/.ai/tools
```

Pick `<slug>` from the active plan, issue, or topic. Kebab-case, no spaces, no timestamps.

## Format rules

- **Single file.** Everything inline: HTML5, vanilla CSS in `<style>`, vanilla JS in `<script>`. No build step.
- **No external resources.** No CDN `<script src=>`, no `<link href=>` to remote stylesheets, no `@import url(http…)`, no `<img src=https…>`, no runtime `fetch(...)`, no dynamic `import(...)`. Inline SVG; base64-embed small bitmaps if you must.
- **No frameworks** unless the project already uses one — then match it.
- **Real content only.** Use exact data from the prompt, repo, plan, or command output. No lorem ipsum, fake metrics, fake timelines, or placeholder rows unless they are visibly marked as examples.
- **No default-AI aesthetics.** Avoid gratuitous gradients, glassmorphism, neumorphism, emoji headers, "✨" sparkle accents. Pick one accent color, one font stack, restrained spacing.
- **Accessible by default.** Real headings, real buttons, keyboard-reachable interactions, visible focus states, labeled color/status meanings, and `prefers-color-scheme` for dark mode if you ship dark styling at all.
- **Responsive by default.** Check the layout at 360px wide. Do not rely on hover-only controls, hidden horizontal traps, tiny labels, or fixed heights that clip content on mobile.
- **Motion stays optional.** If you animate, respect `prefers-reduced-motion` and keep state changes understandable without motion.
- **No tracking, no telemetry, no analytics.**

When you finish writing the file, run a self-check before reporting done. Substitute `<path>` with the file you just wrote (either `docs/.ai/artifacts/<slug>.html` or `docs/.ai/tools/<slug>.html`):

```fish
rg -n "<script[^>]+src=|<link[^>]+href=|src=['\"]https?://|href=['\"]https?://|url\(['\"]?https?://|@import|\bfetch\s*\(|\bimport\s*\(" <path>
```

Any match must be removed (or shown to be inert content/example text, not executable markup).

For visual, spatial, or interactive artifacts, also run the checklist in `references/visual-quality.md` before reporting done.

## Voice handoff (opt-in)

When — and only when — the user asked for voice or passed `--voice` to `/artifact`, invoke the **`speak` skill** with a ≤100-word summary. The `speak` skill routes through the registered `say` MCP server (`mcp-tts`) and falls back across `google → openai → elevenlabs → say`, so you get a good cloud voice instead of the local `say` default.

Do **not** invoke `tts-notify.py` directly from here — that's the Stop/Notification hook path, not an agent primitive. Do **not** call any voice path unprompted; the Stop hook already speaks turn completion and double-speaking is annoying. If the user didn't ask for voice, hand the spoken-text blurb back as plain output and let them trigger TTS themselves.

## References

- [references/visual-quality.md](references/visual-quality.md) — visual taxonomy, standalone design rules, accessibility/responsive checks, and pre-handoff checklist.
- [references/status-snapshot.md](references/status-snapshot.md) — long-work status snapshot template (timeline, counts, validation matrix, decision log, voice blurb).
- [references/interactive-editor.md](references/interactive-editor.md) — throwaway editor patterns (drag-drop, sliders, export-to-markdown).

## Return format

After writing the file, tell the user:

1. The repo-relative path (`docs/.ai/artifacts/<slug>.html` or `docs/.ai/tools/<slug>.html`).
2. How to open it (`open <path>` on macOS).
3. Whether it's durable or throwaway, and the `git add -f <path>` instruction if durable.
4. Any voice summary you spoke, or — if voice wasn't requested — the spoken-text blurb so the user can trigger TTS themselves.
