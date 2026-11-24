#!/bin/sh
# Install the launcher from rexurrect v0.3.3 (ca7cbd84) plus the Codex grant for a
# linked worktree's Git directories and the dedicated GitHub token for Codex. It
# names the pane by REX_BLOCK alone, which needs a rexurrect newer than v0.3.6.
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
		# Unmodified upstream launcher from v0.3.3, which this repository installed.
		2d1f6dbc5f84b483870b3d387143c18fb5fb87959e728bdd598aeb7f232cbb11) ;;
		# This repository's launcher before it passed Codex the GitHub token.
		2d2e6b6b498a6141f46776f7af5b68ac258d81cd0ae57cb8ecd79edd5f7d57df) ;;
		# This repository's launcher before it kept the receipt of an agent that cannot start.
		287cedf7ca2bf0f120fb2bd5d042ddf92401e415fdf978e2cee12407749e904d) ;;
		# This repository's launcher before it named the pane by REX_BLOCK alone.
		4961822256ce5b47196f1b6661a2e69f880f4a1d50aa1910589ab61ba7267168) ;;
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
