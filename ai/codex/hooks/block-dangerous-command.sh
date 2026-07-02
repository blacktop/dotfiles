#!/bin/bash
set -euo pipefail

# Codex PreToolUse hook for Bash. Blocks high-risk command patterns before
# execution. This is a guardrail; sandboxing and approval policy remain the
# safety boundary.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[[ -z "$cmd" ]] && exit 0

command_prefix='(^|;[[:space:]]*|&&[[:space:]]*|[|][|][[:space:]]*|[|][[:space:]]*)'
git_add_force_re="${command_prefix}git[[:space:]]+add([^;&|]*)--force"
git_add_force_re+='|'"${command_prefix}"'git[[:space:]]+add([^;&|]*)[[:space:]]-f([[:space:]]|$)'
push_force_re='git[[:space:]]+push([^;&|]*)--force'
push_force_re+='|git[[:space:]]+push([^;&|]*)[[:space:]]-f([[:space:]]|$)'
direct_main_re='git[[:space:]]+push([^;&|]*[[:space:]])?'
direct_main_re+='(origin[[:space:]]+)?(main|master)([[:space:]]|$)'

block() {
	printf 'BLOCKED: %s\n' "$1" >&2
	exit 2
}

if printf '%s\n' "$cmd" | grep -qiE "${command_prefix}rm[[:space:]]" &&
	printf '%s\n' "$cmd" | grep -qiE '(^|[[:space:]])-[a-zA-Z]*[rR]|--recursive' &&
	printf '%s\n' "$cmd" | grep -qiE '(^|[[:space:]])-[a-zA-Z]*[fF]|--force'; then
	block "Use trash instead of rm -rf."
fi

if printf '%s\n' "$cmd" | grep -qiE "${command_prefix}sudo([[:space:]]|$)"; then
	block "Do not run sudo from Codex without explicit human approval."
fi

if printf '%s\n' "$cmd" | grep -qiE "${command_prefix}mkfs([.[:alnum:]_-]*)([[:space:]]|$)"; then
	block "Refusing filesystem formatting commands."
fi

if printf '%s\n' "$cmd" | grep -qiE "${command_prefix}dd([[:space:]]|$)"; then
	block "Refusing raw disk write command dd."
fi

if printf '%s\n' "$cmd" | grep -qiE 'wget[^|]*[|][[:space:]]*(bash|sh)([[:space:]]|$)'; then
	block "Do not pipe downloaded scripts directly into a shell."
fi

if printf '%s\n' "$cmd" | grep -qiE "$git_add_force_re"; then
	block "Do not force-add ignored files from Codex. Use plain git add, or have the user force-add intentionally."
fi

if printf '%s\n' "$cmd" | grep -qiE "$push_force_re"; then
	block "Do not force-push unless the user explicitly requested it."
fi

if printf '%s\n' "$cmd" | grep -qiE 'git[[:space:]]+reset[[:space:]]+--hard'; then
	block "Do not run git reset --hard unless the user explicitly requested it."
fi

if printf '%s\n' "$cmd" | grep -qiE "$direct_main_re"; then
	block "Use feature branches and PRs; do not push directly to main/master."
fi

exit 0
