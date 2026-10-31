#!/bin/sh
set -eu

binary=$(command -v rex || true)
destination="$HOME/.local/bin/rex"
legacy='/Applications/Rex Beta.app/Contents/Helpers/Rex Server.app/Contents/MacOS/rex'
[ -n "$binary" ] || [ ! -x "$destination" ] || binary=$destination

if [ -n "$binary" ]; then
	printf 'Using Rex CLI at %s\n' "$binary"
else
	for candidate in \
		'/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex' \
		"$legacy"; do
		[ -x "$candidate" ] || continue
		binary=$candidate
		break
	done
	if [ -z "$binary" ]; then
		printf 'Rex is not installed; skipping setup.\n'
		exit 0
	fi
	if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$legacy" ]; then
		ln -sfn "$binary" "$destination"
		printf 'Updated Rex CLI link at %s\n' "$destination"
	elif [ -e "$destination" ] || [ -L "$destination" ]; then
		printf 'Kept existing %s; it is not an available Rex CLI.\n' "$destination"
		exit 0
	else
		mkdir -p "$HOME/.local/bin"
		ln -s "$binary" "$destination"
		printf 'Linked Rex CLI at %s\n' "$destination"
	fi
fi

# Rex owns these files. Its installer preserves unrelated hooks and is safe to
# rerun when the app updates or a new account profile appears.
for variant in claude claude-ddb claude-team; do
	profile="$HOME/.$variant"
	[ -d "$profile" ] || continue
	env CLAUDE_CONFIG_DIR="$profile" "$binary" skill setup --agent claude
done
for variant in codex codex-team codex-api; do
	profile="$HOME/.$variant"
	[ -d "$profile" ] || continue
	env CODEX_HOME="$profile" "$binary" skill setup --agent codex
done
