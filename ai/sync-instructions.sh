#!/bin/sh
# Rebuild installed instructions from public sources and an optional private tail.
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
destination_root=${1:-$HOME}
private_root=${2:-${PRIVATE_SKILLS_DIR:-$script_dir/../../private-skills}}
temporary=''
trap '[ -z "$temporary" ] || rm -f "$temporary"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

for profile in claude claude-team claude-ddb codex codex-team codex-api; do
	case "$profile" in
	claude*)
		family=claude
		document=CLAUDE.md
		;;
	codex*)
		family=codex
		document=AGENTS.md
		;;
	esac
	directory="$destination_root/.$profile"
	[ -d "$directory" ] || continue
	temporary=$(mktemp "$directory/.instructions.XXXXXX")
	cat "$script_dir/$family/$document" >"$temporary"
	if [ -f "$private_root/$document" ]; then
		printf '\n\n' >>"$temporary"
		cat "$private_root/$document" >>"$temporary"
	fi
	chmod 600 "$temporary"
	mv -f "$temporary" "$directory/$document"
	temporary=''
done
