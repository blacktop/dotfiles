#!/bin/sh
# Install the unmodified launcher shipped by rexurrect v0.3.3 (ca7cbd84).
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
destination_root=${1:-$HOME}
source="$script_dir/rexurrect-launch"
target="$destination_root/.local/bin/rexurrect-launch"

mkdir -p "$destination_root/.local/bin"
if ! { [ -x "$target" ] && cmp -s "$source" "$target"; }; then
	[ ! -L "$target" ] || {
		printf 'Kept custom rexurrect-launch symlink: %s\n' "$target" >&2
		exit 1
	}
	if [ -e "$target" ] && ! cmp -s "$source" "$target"; then
		installed_hash=$(shasum -a 256 "$target" | awk '{print $1}')
		case "$installed_hash" in
		# Unmodified upstream launcher from v0.2.0-v0.3.1.
		6c166c1f5e6476b9022d136be38eeb94c27611c860918b0851170265599d591f) ;;
		*)
			printf 'Kept custom rexurrect-launch file: %s\n' "$target" >&2
			exit 1
			;;
		esac
	fi
	install -m 0755 "$source" "$target"
fi

# These former dotfiles helpers are no longer called. Remove only our links.
function_source=$(CDPATH='' cd -- "$script_dir/../fish/functions" && pwd)
for name in _rexurrect_codex _rexurrect_claude; do
	target="$destination_root/.config/fish/functions/$name.fish"
	if [ -L "$target" ] && [ "$(readlink "$target")" = "$function_source/$name.fish" ]; then
		rm "$target"
	fi
done
