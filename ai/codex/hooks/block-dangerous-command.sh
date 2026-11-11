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

# A host that opted into YOLO mode through ai/setup.sh has no sandbox, approvals
# or exec rules, so this hook is its only guard. It allows plain pushes and
# force-adds there, and adds the checks the sandbox and rules used to make.
yolo=0
[[ ! -e "$HOME/.agents/yolo" ]] || yolo=1

block() {
	printf 'BLOCKED: %s\n' "$1" >&2
	exit 2
}

if printf '%s\n' "$cmd" | grep -qiE "${command_prefix}rm[[:space:]]" &&
	printf '%s\n' "$cmd" | grep -qiE '(^|[[:space:]])-[a-zA-Z]*[rR]|--recursive' &&
	printf '%s\n' "$cmd" | grep -qiE '(^|[[:space:]])-[a-zA-Z]*[fF]|--force'; then
	block "Use trash instead of rm -rf."
fi

# The command a `gcloud compute ssh --command` passes runs on the remote host, so
# a sudo inside it is not local. Remove that quoted argument before checking;
# a sudo anywhere else, including chained after the gcloud call, still blocks.
remote_command_re='(gcloud[[:space:]]+compute[[:space:]]+ssh[^;&|]*--command)(=|[[:space:]]+)'
remote_command_re+="('[^']*'|\"[^\"]*\")"
local_cmd=$(printf '%s\n' "$cmd" | sed -E "s/$remote_command_re/\\1 REMOTE/g")
if printf '%s\n' "$local_cmd" | grep -qiE "${command_prefix}sudo([[:space:]]|$)"; then
	block "Do not run sudo from Codex without explicit human approval."
fi

if printf '%s\n' "$cmd" | grep -qiE "${command_prefix}mkfs([.[:alnum:]_-]*)([[:space:]]|$)"; then
	block "Refusing filesystem formatting commands."
fi

if printf '%s\n' "$cmd" | grep -qiE "${command_prefix}dd([[:space:]]|$)"; then
	block "Refusing raw disk write command dd."
fi

if printf '%s\n' "$cmd" | grep -qiE '(wget|curl)[^|]*[|][[:space:]]*(bash|sh)([[:space:]]|$)'; then
	block "Do not pipe downloaded scripts directly into a shell."
fi

if ((yolo)); then
	secret_re='Library/Keychains|/\.gnupg|/auth\.json|\.git-credentials|/\.netrc|locals\.fish'
	secret_re+="|${command_prefix}security[[:space:]]+find-"
	secret_re+="|${command_prefix}(env|printenv)[[:space:]]*([|;&>]|$)"
	if printf '%s\n' "$cmd" | grep -qE "$secret_re"; then
		block "Do not read secret stores or dump the environment."
	fi
	publish_re="${command_prefix}(cargo|npm|pnpm|uv)[[:space:]]+publish"
	publish_re+="|${command_prefix}gh[[:space:]]+(release|repo)[[:space:]]+delete"
	publish_re+="|${command_prefix}diskutil[[:space:]]+(erase|partitionDisk)"
	if printf '%s\n' "$cmd" | grep -qE "$publish_re"; then
		block "Publishing, remote deletion and disk erasure are user-run."
	fi
	# The push parser is skipped below, so match what it resolved for the checks
	# after it: Git global options (-C, -c) before the subcommand, clustered -f,
	# +refspecs, and the force-push alias git/setup.sh defines.
	git_words='git([[:space:]]+[^;&|]*)?[[:space:]]+'
	rewrite_re="${git_words}push([^;&|]*)(--force|[[:space:]]-[a-zA-Z]*f|[[:space:]][+][^[:space:]])"
	rewrite_re+="|${git_words}please([[:space:]]|\$)"
	rewrite_re+="|${git_words}reset([[:space:]]+[^;&|]*)?[[:space:]]+--hard"
	if printf '%s\n' "$cmd" | grep -qE "$rewrite_re"; then
		block "Force-push and git reset --hard are user-run."
	fi
fi

if ((! yolo)) && printf '%s\n' "$cmd" | grep -qiE "$git_add_force_re"; then
	block "Do not force-add ignored files from Codex. Use plain git add, or have the user force-add intentionally."
fi

# The parser is shared with Claude and installed once, in the shared hooks directory.
# A copy beside this script is used only when that one is missing, so an old
# per-profile copy can never shadow the current parser.
script_dir=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
push_parser="$HOME/.agents/hooks/check-git-push.py"
[ -f "$push_parser" ] || push_parser="$script_dir/check-git-push.py"
# Aliases are resolved in the directory the command will run in.
working_directory=$(printf '%s' "$input" | jq -r '.cwd // empty')
((yolo)) || python3 "$push_parser" "$cmd" "$working_directory" ||
	block "Git safety check rejected this command."

if printf '%s\n' "$cmd" | grep -qiE "$push_force_re"; then
	block "Do not force-push unless the user explicitly requested it."
fi

if printf '%s\n' "$cmd" | grep -qiE 'git[[:space:]]+reset[[:space:]]+--hard'; then
	block "Do not run git reset --hard unless the user explicitly requested it."
fi

exit 0
