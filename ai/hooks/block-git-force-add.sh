#!/bin/bash
set -euo pipefail

# Claude Code PreToolUse hook for Bash. Blocks force-adding ignored files;
# the user can still run git add -f intentionally outside the agent.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[[ -z "$cmd" ]] && exit 0

command_prefix='(^|;[[:space:]]*|&&[[:space:]]*|[|][|][[:space:]]*|[|][[:space:]]*)'
git_add_force_re="${command_prefix}git[[:space:]]+add([^;&|]*)--force"
git_add_force_re+='|'"${command_prefix}"'git[[:space:]]+add([^;&|]*)[[:space:]]-f([[:space:]]|$)'

if printf '%s\n' "$cmd" | grep -qiE "$git_add_force_re"; then
	printf 'BLOCKED: Do not force-add ignored files from Claude Code. Use plain git add, or have the user force-add intentionally.\n' >&2
	exit 2
fi

exit 0
