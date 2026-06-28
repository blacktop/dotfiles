---
name: high-tide
description: Context pressure checkpoint, self-handoff, and durable lesson capture workflow. Use when an agent is near the context limit, context usage is above 98%, auto-compaction or context warnings appear, the user says high tide, before `/clear`, or after a long confusing/debugging session where lessons learned should be preserved for the next fresh session or written to project-local `docs/.ai/lessons/`.
---

# High Tide

Use this skill to stop before context quality drops, capture the facts that matter, persist durable project lessons when warranted, and produce a restart handoff for the same work after the user runs `/clear`.

## When to Use

- Use when measured context usage is above `98%`, a context-limit or auto-compaction warning appears, or the user invokes `$high-tide`.
- Use before the user runs `/clear` so the next fresh session can resume from a compact handoff instead of the full transcript.
- Use after a long debugging or research session where confusion, false trails, blockers, or hard-won corrections would save future agents real time.
- Use when a project lesson should be saved to the most specific `docs/.ai/lessons/` directory before the current context is discarded.

## When NOT to Use

- Do not interrupt a short, low-context task just to produce process notes.
- Do not create files when the user requested read-only, review-only, report-only, or diagnostic-only work.
- Do not replace a requested final answer with a handoff when the task is already complete.
- Do not claim a context threshold was crossed unless a measured source reports it.
- Do not write project lessons for one-off session trivia, ordinary command failures, or facts already obvious from existing docs.

## Trigger Check

At natural checkpoints and before large exploratory reads, check a measured context signal. Do not invent a percentage.

Use `scripts/context_percent.py` when a measured payload or status snippet is available and a normalized used percentage is needed. The helper accepts Claude status-line JSON, rendered status-line text such as `ctx:87%`, Codex `/status` text, or an explicit value marked with `--mode used` or `--mode remaining`. It exits `0` only when it found a measured context percentage, `1` when no measured value was present, and `2` for invalid or conflicting input. Record the helper's reported `source` in the handoff.

Use these sources, in order:

- Claude Code status-line JSON, when available to the agent, a wrapper, or a helper script: read `context_window.used_percentage`. This is the documented machine-readable field passed on stdin to configured status-line commands. In this dotfiles repo, `ai/claude/statusline.sh` demonstrates the exact extraction with `jq -r '.context_window.used_percentage // empty'`.
- The status-line script source is not the live value. It proves which field to use; the measured value must come from the current status-line stdin payload, rendered status-line output such as `ctx:87%`, or a file/artifact written from that payload.
- Persisted status-line telemetry, when configured by the project or user: read the file or artifact produced from the same status-line JSON and record its path and timestamp as the context source. This is the preferred autonomous route when an agent cannot directly see the UI footer or status-line stdin.
- Claude Code interactive state: ask for or use `/context` if the user/harness can provide its output. Use the displayed context usage percent or free-space percent from that output.
- Codex CLI or Codex IDE/app: use `/status` for thread/context/rate-limit status. If the TUI footer is configured, use `/statusline` context items such as `context-remaining` or context percentage. When the visible Codex value is remaining context, convert it to used percentage with `scripts/context_percent.py --mode remaining` or feed the full `/status` text to the helper.
- Harness-provided notices: use an explicit UI meter, system context-budget notice, or tool-provided remaining-context value only if it is surfaced as a concrete number.
- Transcript/log analyzers: use only if they read actual recorded usage/context fields. Label the source and timestamp in the handoff.

Do not use these as context-usage truth:

- ordinary shell environment variables. Current Claude/Codex context usage is not documented as a normal env var. Claude env vars such as `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` and `CLAUDE_CODE_AUTO_COMPACT_WINDOW` configure behavior; they do not report current usage. This differs from status-line JSON, which is a host-provided stdin payload to a specific configured command, not a process-wide env var.
- estimates from number of tool calls, file reads, or elapsed time. If no measured surface exists, say `context usage: unknown` and trigger only from warnings, context rot symptoms, or explicit user request.

Start high tide immediately when:

- a measured context meter is `>98%`
- auto-compact or near-limit warning appears
- the user invokes `$high-tide` or says they are about to run `/clear`
- the agent notices context rot symptoms: repeating rejected approaches, losing file/branch state, or needing to re-read the same context repeatedly

Immediately means stop adding substantial new material to the parent context. A bounded sub-agent, worker, or external workflow that receives its own fresh context is a valid exception when the user/environment allows it and the parent agent will not need to read a large result before handing off. In that case, write a minimal checkpoint first, delegate the next narrow task, then high-tide before ingesting bulky outputs or resuming broad parent-context exploration.

If the meter is unavailable, do not guess. Record `context usage: unknown; measured source unavailable` and use judgment only to decide whether a handoff is prudent. A long tool-heavy debugging session with unresolved confusion is enough reason to produce a high-tide handoff, but not enough reason to claim `>98%`.

If a status line visibly shows a context value such as `ctx:87%`, treat that as measured only when it comes from `context_window.used_percentage` or an equivalent documented context field. Record the source as `statusline` and include the script/path if known.

Prefer a high-tide handoff plus `/clear` over `/compact` unless the user explicitly asks for compaction. If automatic compaction already happened, record that as a possible fidelity loss in the handoff.

### Helper Examples

```bash
# Claude status-line JSON payload from stdin.
scripts/context_percent.py --json < statusline-payload.json

# Rendered Claude status-line output.
printf '%s\n' 'ctx:87%' | scripts/context_percent.py --json

# Codex footer or /status value that is explicitly remaining context.
scripts/context_percent.py --mode remaining --json '4%'

# Validate parser behavior after editing the skill.
scripts/context_percent.py --self-test
```

## Stop Rule

Pause new implementation work once high tide triggers. Do only the minimum reading needed to make the handoff accurate. Do not run broad searches or new experiments just to make the handoff more complete.

Do not use delegation as a loophole for more parent-context work. It is only appropriate when the delegated agent/workflow can operate from a compact prompt and return a compact result, or when its output can be referenced as an artifact path for the next fresh session.

If the current user request was read-only, report-only, review-only, diagnostic-only, or otherwise forbids writes, do not create files; return the handoff in the response. Otherwise, save a durable note if the repo/workspace convention is clear.

Prefer these paths:

- repo-local: `docs/.ai/handoffs/<timestamp>-high-tide-<slug>.md`
- no repo or writes unavailable: return a fenced handoff for the user to paste after `/clear`

Do not edit global or agent-memory files unless the user explicitly asks. Project-local lesson files under `docs/.ai/lessons/` are allowed when they meet the Project Lessons criteria and the current task permits writes.

## Gather

Capture only execution-critical context. Use concrete file paths, commands, artifacts, and dates. Include:

- objective and current task
- measured context usage and source, or `unknown` with why it is unavailable
- branch, worktree, repo, and current directory
- files changed or read that matter
- commands/tests run and exact pass/fail state
- completed work and current state
- remaining work, next smallest action, and stop rules
- constraints from the user or repo instructions
- blockers, assumptions, and open questions
- generated artifacts or reports and where they live

## Lessons Learned

This is the part future agents usually need most. Record the expensive parts of the session:

- confusion: what was misunderstood or unclear
- false trail: what was tried or considered and why it was wrong
- blocker: what actually stopped progress
- correction: the evidence or command that resolved it
- future shortcut: what the next agent should do first or avoid

Keep this operational. Do not include private chain-of-thought; summarize observable misunderstandings, rejected hypotheses, and evidence.

## Project Lessons

Write a separate lesson file when a lesson is durable beyond the current handoff:

- it corrects a recurring misconception about the project
- it records a non-obvious command, fixture, artifact, or oracle future agents should use
- it explains why an approach was rejected and that rejection should not be rediscovered
- it documents a repo-specific workflow trap, ignored-file behavior, nested repo boundary, or test baseline
- it applies to more than the current session's next step

Choose the most specific project root that owns the lesson:

- single-project repo: `<repo>/docs/.ai/lessons/<yyyy-mm-dd>-<slug>.md`
- multi-crate Rust workspace, crate-specific lesson: `<repo>/<crate>/docs/.ai/lessons/<yyyy-mm-dd>-<slug>.md`
- multi-crate Rust workspace, cross-crate/workspace lesson: `<repo>/docs/.ai/lessons/<yyyy-mm-dd>-<slug>.md`
- nested repo or submodule: use that nested repo's `docs/.ai/lessons/`
- no writable workspace or write-forbidden task: include a `Project lesson candidate` section in the handoff instead of creating a file

Prefer the nearest `Cargo.toml` package root for Rust crate-specific lessons. Use the workspace root only when the lesson applies across crates or to workspace-level commands.

Use this lesson format:

```markdown
# [Short Lesson Title]

Date: [YYYY-MM-DD]
Scope: [repo, crate, package, or subsystem path]

## Lesson

[One durable fact future agents should know.]

## Evidence

- [command, file, artifact, error, or source path]

## Future Shortcut

[What to do first next time, or what not to retry.]
```

If `docs/.ai/` is gitignored, still write the file when writes are allowed and mention in the final response that it may require `git add -f` if the user wants it tracked.

## Build The Handoff

If the `handoff` skill is available, read it and use its fresh-context handoff shape for the restart prompt. In this install it usually lives at `/Users/blacktop/.agents/skills/handoff/SKILL.md`. Target the same agent family unless the user names another one. For Codex, use OpenAI/Codex.

Use this fallback format:

```markdown
# High Tide Handoff

## Restart Prompt

You are continuing after `/clear`. Use only this handoff plus the repo files you verify. Do not assume earlier chat context exists.

## Objective

[Single concrete outcome]

## Current State

- context usage:
- context source:
- project lessons saved:
- repo/worktree:
- branch:
- cwd:
- completed:
- changed files:
- important read-only context:

## Lessons Learned / Time Savers

- confusion:
  correction:
  future shortcut:
- false trail:
  why rejected:
  evidence:

## Remaining Work

- next smallest action:
- known blockers:
- open questions:
- stop rules:

## Verification

- commands already run:
- commands to run next:
- expected pass/fail baseline:

## Fresh Session Instructions

1. Re-read this handoff.
2. Verify current repo state before editing.
3. Continue from the next smallest action.
4. Report any mismatch between this handoff and the filesystem before proceeding.
```

## Final Response

When high tide is complete, tell the user:

- whether the handoff was saved to a file or returned inline
- any project lesson files written, or `none`
- the exact path if saved
- the recommended restart action: run `/clear`, then paste or reference the handoff
- any unfinished verification or uncertainty

For rationale and comparable patterns, read `references/context-patterns.md` only when revising this skill or explaining why this workflow exists.
