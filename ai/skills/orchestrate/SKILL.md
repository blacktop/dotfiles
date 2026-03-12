---
name: orchestrate
description: Orchestrate multi-step work with Claude Code CLI as a bounded worker while Codex stays lead developer. Use when Codex should split a task into scoped sub-tasks, delegate planning or implementation to Claude with `claude -p`, run parallel Claude sessions, isolate risky edits in worktrees, define custom Claude subagents, or move repeated enforcement into Claude hooks/settings.
---

# Orchestrate

Keep architecture, acceptance, and integration local. Delegate bounded work only.

## Read the right reference

- Read [references/orchestration.md](references/orchestration.md) for task decomposition, delegation rules, parallelism, context isolation, review loops, and evaluation.
- Read [references/claude-cli.md](references/claude-cli.md) for the current `claude` CLI surface: `-p`, structured output, permission modes, worktrees, and custom agents.

## Lead versus worker

- Lead (Codex): architecture, task graph, owned-file boundaries, acceptance criteria, integration, and final verification.
- Worker (Claude): bounded research, boilerplate, repetitive refactors, first-pass implementation, docs, and mechanical edits.

Do not hand off the part where a wrong decision would invalidate the rest of the work.

## When to use this skill

- the task is larger than one coherent edit
- multiple sub-tasks can run independently
- a repetitive or high-volume slice can be delegated
- you want Claude to work in an isolated worktree or with restricted tools
- you need a repeatable orchestration pattern, not just a single prompt

## When not to use it

- the next step is urgent and tightly coupled to your own reasoning
- the change is trivial enough to do directly
- the repo or task should not leave the current agent boundary
- overlapping write scopes would make parallel work risky

## Default workflow

1. Define success, stop rules, and what stays local.
2. Break the task into atomic units with clear ownership.
3. Choose execution mode per unit:
   - read-only research or planning
   - bounded edit in current tree
   - isolated edit in a worktree
4. Build a short handoff with:
   - one concrete goal
   - files to read first
   - owned files and forbidden files
   - exact verification commands
   - return format
5. Run independent workers in parallel only when their write scopes do not overlap.
6. Review Claude’s output or diff before integrating.
7. Run local verification yourself.
8. If the pattern repeats, promote it into `.claude/agents`, hooks, or project settings.

## Core rules

- Fresh Claude session by default for each delegated unit.
- Use `--continue` only when continuity matters more than clean context.
- Prefer structured output for plans, task maps, and review summaries.
- Prefer tool and permission restrictions over prompt-only restrictions.
- Use worktrees for risky or concurrent edit tasks.
- Move deterministic enforcement into hooks, not repeated prose reminders.
- Record what Claude owned, what you owned, and what was verified.
