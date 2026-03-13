# Gemini CLI

Current local verification snapshot:

- CLI: `gemini 0.33.0`
- Installed review-related extensions:
  - `code-review`
  - `gemini-cli-security`
- CLI supports:
  - `--approval-mode`
  - `--extensions`
  - `--output-format`

Relevant official and current sources:

- local Gemini CLI help
- local `code-review` extension metadata and commands
- Gemini prompting guidance
- Gemini model docs

## Safety default

For second-opinion reviews, prefer:

```bash
--approval-mode plan
```

Do not default to `--yolo`. A second opinion should be read-only.

## Model selection

Best practice:

- prefer the local CLI default model unless the user asked to pin one
- if you need a current tested pin, use `gemini-3.1-pro-preview`
- do not use `gemini-3-pro-preview`; Google's model docs mark it deprecated and shut down as of 2026-03-09

## Extension usage

### Current branch review

The installed `code-review` extension provides `/code-review` and is the preferred path when the user wants review of the current branch change set.

Use:

```bash
gemini \
  --approval-mode plan \
  -e code-review \
  -p "/code-review"
```

Important:

- the extension reviews current branch changes, not an arbitrary commit or uncommitted-only scope
- keep it for branch-level review

### Pull request review

Use `/pr-code-review` only when:

- the user asked for a PR review
- GitHub PR context is available
- the needed GitHub MCP setup exists

## Custom scope review

For uncommitted changes, branch diffs against a chosen base, or specific commits, use a short review brief and tell Gemini the exact git command to run.

Prefer prompt files or stdin for the brief:

```bash
gemini \
  --approval-mode plan \
  -e code-review \
  -p "$(<"$prompt_file")"
```

The prompt file should:

- state the focus area
- define the scope
- tell Gemini which git command to run
- instruct it to read AGENTS.md or CLAUDE.md if present
- require findings-first output
- restate the read-only rule

## Security focus

For a light second-opinion security review, use a security-focused brief.

Do not default to the heavy `/security:analyze` workflow from the security extension inside this skill. That command is its own deeper audit flow and creates artifacts. Use the dedicated security skill if the user wants a full security analysis rather than a lightweight second opinion.

## Output handling

Prefer text output for human review summaries unless you are explicitly building machine parsing around Gemini:

- `--output-format text` for normal use
- `--output-format json` only if you are actually parsing it

For automation:

- use an explicit timeout around the Gemini process
- capture stdout and stderr separately or with a bounded wrapper
- treat silent hangs or auth prompts as operational failures and report them clearly
