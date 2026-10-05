#!/bin/sh
# Apply persistent telemetry opt-outs without updating or installing tools.
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
destination_root=${1:-$HOME}
# shellcheck source=privacy/env.sh
. "$script_dir/env.sh"

if command -v go >/dev/null 2>&1; then
	go telemetry off
	[ "$(go telemetry)" = off ] || {
		printf 'Go telemetry opt-out did not take effect.\n' >&2
		exit 1
	}
	printf 'Go telemetry: off (local collection and uploads).\n'
else
	printf 'Go is not installed; rerun privacy/setup.sh after installing it.\n'
fi

if command -v brew >/dev/null 2>&1; then
	brew analytics off
	printf 'Homebrew analytics: off.\n'
fi

target="$destination_root/.config/fish/conf.d/00-privacy.fish"
source_file="$script_dir/../fish/conf.d/00-privacy.fish"
if [ -e "$target" ] && [ ! -L "$target" ]; then
	printf 'Keeping existing file: %s; compare it with %s.\n' "$target" "$source_file" >&2
	exit 1
fi
mkdir -p "$(dirname "$target")"
ln -sf "$source_file" "$target"
printf 'Installed Fish telemetry opt-outs; open a new shell to load them.\n'
