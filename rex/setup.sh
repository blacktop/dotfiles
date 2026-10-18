#!/bin/sh
set -eu

binary='/Applications/Rex Beta.app/Contents/Helpers/Rex Server.app/Contents/MacOS/rex'
destination="$HOME/.local/bin/rex"

if [ ! -x "$binary" ]; then
	printf 'Rex Beta is not installed; skipping CLI link.\n'
	exit 0
fi
if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$binary" ]; then
	printf 'Rex CLI is already linked.\n'
	exit 0
fi
if [ -e "$destination" ] || [ -L "$destination" ]; then
	printf 'Kept existing %s; it is not the Rex Beta CLI link.\n' "$destination"
	exit 0
fi

mkdir -p "$HOME/.local/bin"
ln -s "$binary" "$destination"
printf 'Linked Rex CLI at %s\n' "$destination"
