---
name: are-you-sure
description: Deliberate fresh-eyes self-review and repair after making changes. Use when an agent has just written or modified code, config, tests, or docs and should pause to look for obvious bugs, regressions, missing tests, confusing behavior, or risky assumptions, fix the clear local issues it finds, and only then finalize, hand off, or commit. Supports Claude Code, Codex, and Gemini with provider notes in references/.
---

# Are You Sure

Do one careful second pass on the changes you just made, and fix the clear issues you find before you declare the work done.

## Read the right reference

- Read [references/workflow.md](references/workflow.md) for the provider-neutral fresh-eyes review loop.
- Read [references/claude.md](references/claude.md) if this should run in Claude Code.
- Read [references/codex.md](references/codex.md) if this should run in Codex.
- Read [references/gemini.md](references/gemini.md) if this should run in Gemini CLI.

## Use this skill when

- you just edited files and are about to send a final answer
- you are about to commit or open a PR
- the change involved generated or agent-written code
- the edit touched behavior, configuration, tests, or interfaces
- you want a quick self-check before asking for a second opinion

## Do not use this skill as

- a substitute for real verification
- a substitute for a dedicated security audit
- a substitute for an external second-opinion review

If the change is high-risk, run this skill first, then use a separate review skill.

## Fresh-eyes workflow

1. Reconstruct the exact scope of what changed.
2. Re-read the diff and changed files slowly.
3. Check the five risk buckets from the workflow reference.
4. Run the cheapest meaningful verification you can.
5. If you find a likely issue, inspect neighboring code before concluding.
6. Default to fix mode: if the issue is clear, local, and easy to verify, patch it immediately.
7. Re-run the narrowest relevant verification and repeat the review once.
8. If the fix would widen scope, change architecture, or needs human judgment, stop and report it instead of guessing.
9. Return what you fixed, what still looks risky, or say explicitly that no substantive issues were found.

## Output contract

Return in this order:

1. Issues found and fixed, with file references.
2. Issues still remaining or explicitly review-only findings.
3. Verification performed.
4. Residual risk, open questions, or `No substantive issues found`.

Keep the review concrete. Do not pad it with praise or a changelog.
