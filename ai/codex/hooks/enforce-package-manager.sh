#!/bin/bash
set -euo pipefail

# Codex PreToolUse hook for Bash. Blocks npm commands in projects that use pnpm.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // env.PWD')

[[ -z "$cmd" ]] && exit 0
[[ ! -f "$cwd/pnpm-lock.yaml" ]] && exit 0

if printf '%s\n' "$cmd" | grep -qE '(^|;[[:space:]]*|&&[[:space:]]*)npm([[:space:]]|$)'; then
	printf 'BLOCKED: This project uses pnpm, not npm. Use pnpm instead.\n' >&2
	exit 2
fi

exit 0
