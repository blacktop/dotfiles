#!/bin/sh
# Link a local private checkout without fetching or publishing its contents.
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
private_root=${1:-${PRIVATE_SKILLS_DIR:-$script_dir/../../private-skills}}
destination=${2:-$HOME/.agents/skills}

notice() {
	if command -v gum >/dev/null 2>&1; then
		gum style --foreground '#FF9400' "  • $1"
	else
		printf '  • %s\n' "$1"
	fi
}

if [ ! -d "$private_root" ]; then
	notice 'Private skills skipped. Clone your private-skills repo beside dotfiles, then rerun the skill sync.'
	exit 0
fi
private_root=$(CDPATH='' cd -- "$private_root" && pwd -P)
if [ ! -d "$private_root/skills" ]; then
	notice 'Private checkout found. Add skills/<name>/SKILL.md there, then rerun the skill sync.'
	exit 0
fi

# A local ownership ledger allows pruning and checkout moves without touching
# unrelated links. Exact current links from the old installer are adopted.
mkdir -p "$destination"
state="$destination/.private-skill-links"
if [ -L "$state" ] || { [ -e "$state" ] && [ ! -d "$state" ]; }; then
	printf 'Invalid private skill ownership directory: %s\n' "$state" >&2
	exit 1
fi
temporary=''
trap '[ -z "$temporary" ] || rm -f "$temporary"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$state"

owned_link() {
	[ -L "$target" ] && [ -f "$state/$name" ] &&
		[ ! -L "$state/$name" ] &&
		[ "$(readlink "$target")" = "$(cat "$state/$name")" ]
}
conflict() {
	printf 'Private skill conflicts with installed skill: %s. Preserve or move that entry before retrying; if it is a stale symlink, remove only the symlink.\n' "$name" >&2
	exit 1
}

# Validate ownership and all collisions before changing any skill links.
for record in "$state"/*; do
	[ -e "$record" ] || [ -L "$record" ] || continue
	[ -f "$record" ] && [ ! -L "$record" ] || {
		printf 'Invalid private skill ownership record: %s\n' "$record" >&2
		exit 1
	}
	name=$(basename "$record")
	target="$destination/$name"
	if [ -e "$target" ] || [ -L "$target" ]; then
		owned_link || conflict
	fi
done
for source in "$private_root/skills"/*; do
	[ -d "$source" ] && [ -f "$source/SKILL.md" ] || continue
	name=$(basename "$source")
	target="$destination/$name"
	if [ -d "$script_dir/skills/$name" ]; then
		printf 'Private skill conflicts with public skill: %s\n' "$name" >&2
		exit 1
	fi
	if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
		continue
	fi
	if [ -e "$target" ] || [ -L "$target" ]; then
		owned_link || conflict
	fi
done

for record in "$state"/*; do
	[ -f "$record" ] || continue
	name=$(basename "$record")
	[ -f "$private_root/skills/$name/SKILL.md" ] && continue
	target="$destination/$name"
	if [ -e "$target" ] || [ -L "$target" ]; then
		owned_link || conflict
		rm "$target"
	fi
	rm "$record"
done

count=0
for source in "$private_root/skills"/*; do
	[ -d "$source" ] && [ -f "$source/SKILL.md" ] || continue
	name=$(basename "$source")
	target="$destination/$name"
	if [ -L "$target" ] && [ "$(readlink "$target")" != "$source" ]; then
		owned_link || conflict
		rm "$target"
	fi
	[ -L "$target" ] || ln -s "$source" "$target"
	temporary=$(mktemp "$state/.record.XXXXXX")
	printf '%s\n' "$source" >"$temporary"
	chmod 600 "$temporary"
	mv "$temporary" "$state/$name"
	temporary=''
	count=$((count + 1))
done
notice "Private skills ready: $count linked from your local checkout."
