# Codex CLI

The CLI has built-in non-interactive review commands: `codex review` and `codex exec review`.

Relevant official sources:

- Codex CLI docs
- Codex non-interactive mode docs
- Codex prompting guide
- AGENTS.md guidance

## Preferred path

For headless second-opinion reviews, split the Codex path in two:

- generic scoped review: prefer `codex exec review`
- focused or highly customized review: prefer plain `codex exec`

Why:

- current CLI has first-class review scope flags
- avoids manual diff assembly for common cases
- keeps the review flow closer to the tool's native behavior

## Scope mapping

```bash
# uncommitted changes, including untracked files
codex exec review --uncommitted

# branch diff
codex exec review --base <branch>

# specific commit
codex exec review --commit <sha>
```

## Safe defaults

For generic scoped review, use:

```bash
codex exec review \
  -c sandbox_mode='"read-only"' \
  -c approval_policy='"never"' \
  --ephemeral \
  -o "$output_file" \
  --uncommitted
```

Notes:

- prefer `--ephemeral`
- explicitly force read-only with `-c sandbox_mode='"read-only"'`
- do not use `--dangerously-bypass-approvals-and-sandbox`
- use `-c approval_policy='"never"'` for non-interactive review runs
- do not use manual diff pasting unless the built-in review command cannot support the requested workflow
- let Codex read `AGENTS.md` automatically; do not paste its contents into the prompt

Some CLI versions reject a custom `[PROMPT]` together with `--uncommitted`, `--base`, or `--commit`, even though help lists `[PROMPT]`. For a custom focus, use the focused review path below unless you have confirmed the installed CLI accepts that combination.

## Model selection

Use the local CLI default model unless the user names a specific one.

## Focused review path

When the user wants a custom focus such as performance, security, architecture, or special output constraints, use plain `codex exec` with a review brief.

Example:

```bash
codex exec \
  -c sandbox_mode='"read-only"' \
  -c approval_policy='"never"' \
  --ephemeral \
  -o "$output_file" \
  - < "$prompt_file"
```

The prompt file should tell Codex exactly which git command to run for the requested scope.

## Prompting style

Codex already knows it is reviewing code. Keep custom instructions short:

- focus area
- scope clarification if needed
- output format
- explicit read-only constraint

Example custom prompt body:

```text
Review for correctness, performance regressions, security issues, maintainability risks, and missing tests.
Keep the review read-only. Do not modify files, commit, push, or stage changes.
Read AGENTS.md if present. If not, read CLAUDE.md if present.
Findings first. If no substantive issues are found, say so explicitly.
```

## Fallback

Only fall back to plain `codex exec` when:

- the installed CLI lacks `review`
- you need a custom workflow the review subcommand cannot express

If you fall back, still keep the task read-only and prefer giving Codex the git command to inspect, not a giant pasted diff.
