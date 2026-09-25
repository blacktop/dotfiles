#!/bin/bash
set -euo pipefail

# Claude PreToolUse Bash hook; the parser is shared with the Codex guardrail.
input=$(cat)
command_text=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[[ -z "$command_text" ]] && exit 0
# Aliases are resolved in the directory the command will run in.
working_directory=$(printf '%s' "$input" | jq -r '.cwd // empty')
script_dir=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
if ! python3 "$script_dir/check-git-push.py" "$command_text" "$working_directory"; then
	printf '%s\n' 'BLOCKED: Git safety check rejected a push or destructive operation; the user runs those manually.' >&2
	exit 2
fi
