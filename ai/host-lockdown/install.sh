#!/bin/sh
# Offer to install this host's root-owned agent policy files. They outrank every
# profile and cannot be changed without sudo, by an agent or by a desktop app.
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
# A prefix other than "" is for tests.
prefix=${1:-}
claude_policy="$prefix/Library/Application Support/ClaudeCode/managed-settings.json"
codex_policy="$prefix/etc/codex/requirements.toml"

pending=''
plan() {
	source_file="$1" destination="$2" effect="$3"
	if cmp -s "$source_file" "$destination"; then
		return 0
	fi
	action=install
	[ ! -e "$destination" ] || action=REPLACE
	pending="$pending
  $action $destination
      $effect"
}
jq empty "$script_dir/claude-managed-settings.json"
plan "$script_dir/claude-managed-settings.json" "$claude_policy" \
	"Claude: forbid --dangerously-skip-permissions"
plan "$script_dir/codex-requirements.toml" "$codex_policy" \
	"Codex: pin Computer Use off, including the desktop app's enablement flows"

if [ -z "$pending" ]; then
	printf 'Host lockdown already installed.\n'
	exit 0
fi
if [ ! -t 0 ]; then
	printf 'Host lockdown not installed (no terminal to ask). Run: sh %s/install.sh\n' "$script_dir"
	exit 0
fi
printf 'Host lockdown would use sudo to:%s\n' "$pending"
if ! gum confirm --default=false "Harden this host with these root-owned policy files?"; then
	printf 'Skipped host lockdown.\n'
	exit 0
fi

sudo install -d -m 755 "$(dirname "$claude_policy")" "$(dirname "$codex_policy")"
sudo install -m 644 "$script_dir/claude-managed-settings.json" "$claude_policy"
sudo install -m 644 "$script_dir/codex-requirements.toml" "$codex_policy"
printf 'Installed host lockdown.\n'

# A policy file Codex cannot parse stops it from starting; say so right away.
if command -v codex >/dev/null 2>&1 && ! codex features list >/dev/null 2>&1; then
	printf 'Codex no longer starts. Undo with: sudo rm "%s"\n' "$codex_policy" >&2
	exit 1
fi
