#!/bin/sh
# Install the portable rexurrect plugin into each existing agent profile.
# An optional destination root follows the other ai/sync-* scripts.
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
destination_root=${1:-$HOME}
plugin=rexurrect@rexurrect

die() {
	printf 'rexurrect plugin setup: %s\n' "$*" >&2
	exit 1
}
for binary in jq rex rexurrect; do
	command -v "$binary" >/dev/null 2>&1 || die "requires $binary on PATH"
done
rex version >/dev/null
rexurrect version >/dev/null
set_help=$(rexurrect receipt set --help 2>&1)
clear_help=$(rexurrect receipt clear --help 2>&1)
for flag in host command call-timeout lock-timeout; do
	printf '%s\n' "$set_help" | grep -Eq -- "(^|[[:space:]])--?$flag([[:space:]]|$)" ||
		die "update rexurrect: receipt set lacks --$flag"
done
for flag in command call-timeout lock-timeout; do
	printf '%s\n' "$clear_help" | grep -Eq -- "(^|[[:space:]])--?$flag([[:space:]]|$)" ||
		die "update rexurrect: receipt clear lacks --$flag"
done
if command -v codex >/dev/null 2>&1; then
	codex_help=$(codex --help)
	printf '%s\n' "$codex_help" | grep -Eq -- '(^|[[:space:]])--no-daemon([[:space:]]|$)' ||
		die 'update Codex: --no-daemon is required (CLI 0.163.0 or newer)'
fi
"$script_dir/install-rexurrect-launch.sh" "$destination_root"

# Receipt format 2 requires the portable plugin released as 0.2.0.
version_filter='def compatible: (.version // "0" | split(".") | map(tonumber? // 0)) >= [0,2,0];'

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
	if ! printf '%s' "$installed" | jq -e --arg plugin "$plugin" "$version_filter"'any(.[]; .id == $plugin and .scope == "user" and compatible)' >/dev/null; then
		env CLAUDE_CONFIG_DIR="$profile" claude plugin marketplace update rexurrect
		env CLAUDE_CONFIG_DIR="$profile" claude plugin update "$plugin" --scope user
		installed=$(env CLAUDE_CONFIG_DIR="$profile" claude plugin list --json)
	fi
	if ! printf '%s' "$installed" | jq -e --arg plugin "$plugin" 'any(.[]; .id == $plugin and .scope == "user" and .enabled == true)' >/dev/null; then
		env CLAUDE_CONFIG_DIR="$profile" claude plugin enable "$plugin" --scope user
		installed=$(env CLAUDE_CONFIG_DIR="$profile" claude plugin list --json)
	fi
	printf '%s' "$installed" | jq -e --arg plugin "$plugin" "$version_filter"'any(.[]; .id == $plugin and .scope == "user" and .enabled == true and compatible)' >/dev/null ||
		die "$variant: compatible plugin 0.2.0 or newer is not enabled"
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
	if ! printf '%s' "$installed" | jq -e --arg plugin "$plugin" 'any(.installed[]; .pluginId == $plugin)' >/dev/null; then
		env CODEX_HOME="$profile" codex plugin add "$plugin" --json
		installed=$(env CODEX_HOME="$profile" codex plugin list --marketplace rexurrect --json)
	fi
	if ! printf '%s' "$installed" | jq -e --arg plugin "$plugin" "$version_filter"'any(.installed[]; .pluginId == $plugin and compatible)' >/dev/null; then
		env CODEX_HOME="$profile" codex plugin marketplace upgrade rexurrect --json
		env CODEX_HOME="$profile" codex plugin add "$plugin" --json
		installed=$(env CODEX_HOME="$profile" codex plugin list --marketplace rexurrect --json)
	elif ! printf '%s' "$installed" | jq -e --arg plugin "$plugin" 'any(.installed[]; .pluginId == $plugin and .enabled == true)' >/dev/null; then
		env CODEX_HOME="$profile" codex plugin add "$plugin" --json
		installed=$(env CODEX_HOME="$profile" codex plugin list --marketplace rexurrect --json)
	fi
	printf '%s' "$installed" | jq -e --arg plugin "$plugin" "$version_filter"'any(.installed[]; .pluginId == $plugin and .enabled == true and compatible)' >/dev/null ||
		die "$variant: compatible plugin 0.2.0 or newer is not enabled"
	printf '%s: rexurrect plugin installed and enabled\n' "$variant"
done
