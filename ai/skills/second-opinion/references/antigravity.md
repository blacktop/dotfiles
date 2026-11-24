# Antigravity CLI

Run the review in `agy` print mode on Gemini 4 Neon, Google's model for long agentic coding work. Use `gemini-4-neon-xhigh` unless the user names another model; `agy models` lists the IDs the account can use. Neon needs a paid Google AI Pro or Ultra plan. Print mode exits non-zero on a model the account cannot use instead of falling back to another.

## Command

Put the review brief and the patch in `prompt_file`, then run:

```bash
agy \
  --model gemini-4-neon-xhigh \
  --output-format text \
  --disable-slash-commands \
  --print-timeout 15m \
  -p="$(cat "$prompt_file")" \
  >"$output_file" 2>"$stderr_log"
```

- Keep `-p=` attached to its value, with the other flags before it.
- `--disable-slash-commands` keeps a `/` at the start of a line in the patch from running as a command or skill.
- Paste the patch into the prompt. Print mode keeps the user's permission mode and skips any tool call that needs approval, so the reviewer may not be able to run `git diff` itself. Edits are skipped the same way, unless a rule the user saved always allows them.
- Do not pass `--dangerously-skip-permissions` or `--mode plan`. Plan mode returns a plan, not findings.
- A patch too large for one argument fails to start. Narrow the scope rather than dropping files from the patch.

## Reading the result

Read both the output and `stderr_log`. Print mode exits 0 after skipping a tool call, so look in the log for skipped actions and report them as gaps in coverage. An authentication, quota, model or timeout error is a failed review: report it and keep any partial output.
