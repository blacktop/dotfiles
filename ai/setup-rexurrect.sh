#!/bin/sh
# Install the portable rexurrect plugin into each existing agent profile.
# An optional destination root follows the other ai/sync-* scripts.
set -eu
destination_root=${1:-$HOME}
plugin=rexurrect@rexurrect

command -v jq >/dev/null 2>&1 || {
	printf 'rexurrect plugin setup requires jq.\n' >&2
	exit 1
}

for variant in claude claude-ddb claude-team; do
	profile="$destination_root/.$variant"
	[ -d "$profile" ] || continue
	if ! command -v claude >/dev/null 2>&1; then
		printf 'claude CLI not found; skipping Rexurrect for Claude profiles.\n' >&2
		break
	fi
	marketplaces=$(env CLAUDE_CONFIG_DIR="$profile" claude plugin marketplace list --json)
	if ! printf '%s' "$marketplaces" | jq -e 'any(.[]; .name == "rexurrect" and .source == "github" and .repo == "blacktop/rexurrect")' >/dev/null; then
		if printf '%s' "$marketplaces" | jq -e 'any(.[]; .name == "rexurrect")' >/dev/null; then
			printf '%s: rexurrect marketplace has a different source; review it before replacing it.\n' "$variant" >&2
			exit 1
		fi
		env CLAUDE_CONFIG_DIR="$profile" claude plugin marketplace add blacktop/rexurrect
	fi
	installed=$(env CLAUDE_CONFIG_DIR="$profile" claude plugin list --json)
	if ! printf '%s' "$installed" | jq -e --arg plugin "$plugin" 'any(.[]; .id == $plugin and .scope == "user")' >/dev/null; then
		env CLAUDE_CONFIG_DIR="$profile" claude plugin install "$plugin" --scope user
		installed=$(env CLAUDE_CONFIG_DIR="$profile" claude plugin list --json)
	fi
	if ! printf '%s' "$installed" | jq -e --arg plugin "$plugin" 'any(.[]; .id == $plugin and .scope == "user" and .enabled == true)' >/dev/null; then
		env CLAUDE_CONFIG_DIR="$profile" claude plugin enable "$plugin" --scope user
		installed=$(env CLAUDE_CONFIG_DIR="$profile" claude plugin list --json)
	fi
	printf '%s' "$installed" | jq -e --arg plugin "$plugin" 'any(.[]; .id == $plugin and .scope == "user" and .enabled == true)' >/dev/null
	printf '%s: rexurrect plugin installed and enabled\n' "$variant"
done

for variant in codex codex-team codex-api; do
	profile="$destination_root/.$variant"
	[ -d "$profile" ] || continue
	if ! command -v codex >/dev/null 2>&1; then
		printf 'codex CLI not found; skipping Rexurrect for Codex profiles.\n' >&2
		break
	fi
	marketplaces=$(env CODEX_HOME="$profile" codex plugin marketplace list --json)
	if ! printf '%s' "$marketplaces" | jq -e 'any(.marketplaces[]; .name == "rexurrect" and .marketplaceSource.sourceType == "git" and .marketplaceSource.source == "https://github.com/blacktop/rexurrect.git")' >/dev/null; then
		if printf '%s' "$marketplaces" | jq -e 'any(.marketplaces[]; .name == "rexurrect")' >/dev/null; then
			printf '%s: rexurrect marketplace has a different source; review it before replacing it.\n' "$variant" >&2
			exit 1
		fi
		env CODEX_HOME="$profile" codex plugin marketplace add blacktop/rexurrect --json
	fi
	installed=$(env CODEX_HOME="$profile" codex plugin list --marketplace rexurrect --json)
	if ! printf '%s' "$installed" | jq -e --arg plugin "$plugin" 'any(.installed[]; .pluginId == $plugin and .enabled == true)' >/dev/null; then
		env CODEX_HOME="$profile" codex plugin add "$plugin" --json
		installed=$(env CODEX_HOME="$profile" codex plugin list --marketplace rexurrect --json)
	fi
	printf '%s' "$installed" | jq -e --arg plugin "$plugin" 'any(.installed[]; .pluginId == $plugin and .enabled == true)' >/dev/null
	printf '%s: rexurrect plugin installed and enabled\n' "$variant"
done

# ai/setup.sh can run without a full Fish setup. Keep its new autoload helpers
# available, while preserving helpers with custom executable selection.
function_source=$(CDPATH='' cd -- "$(dirname "$0")/../fish/functions" && pwd)
function_destination="$destination_root/.config/fish/functions"
mkdir -p "$function_destination"
for name in _rexurrect_codex.fish _rexurrect_claude.fish; do
	source="$function_source/$name"
	target="$function_destination/$name"
	if [ -L "$target" ]; then
		[ "$(readlink "$target")" = "$source" ] || {
			printf 'Kept foreign Fish helper link: %s\n' "$target" >&2
			exit 1
		}
	elif [ -e "$target" ]; then
		cmp -s "$source" "$target" || {
			printf 'Fish helper differs from the packaged version; review it before replacing it: %s\n' "$target" >&2
			exit 1
		}
	else
		ln -s "$source" "$target"
	fi
done
