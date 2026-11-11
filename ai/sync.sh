#!/bin/sh
# Apply this repository's agent configuration to the installed profiles: hooks,
# Claude settings, Codex config, instructions and the rexurrect launcher.
# Installs nothing and needs no network; setup.sh calls it and adds the rest.
# Running sessions keep their old sandbox: start new ones to load the changes.
set -eu
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
# shellcheck source=ai/lib.sh
. "$SCRIPT_DIR/lib.sh"

mkdir -p "$HOME/.agents/hooks"
# ai/setup.sh creates this marker when the user opts this host out of hardening.
# The settings and config scripts read it too; Codex exec rules are not installed.
codex_rules=''
if [ -e "$HOME/.agents/yolo" ]; then
	warn "YOLO mode: sandbox and approvals are OFF; only destructive-action and secret guards remain (remove ~/.agents/yolo to harden)"
	codex_rules=rules
fi
msg "Sync shared AI hooks..."
rsync -a --exclude='.DS_Store' --exclude='__pycache__' "$SCRIPT_DIR/hooks/" "$HOME/.agents/hooks/"
# rsync never deletes, so drop what this repository installed and later retired.
"$SCRIPT_DIR/prune-retired.sh" "$SCRIPT_DIR/hooks" "$HOME/.agents/hooks"

# Sync claude + claude-team + claude-ddb from the same source tree.
for variant in claude claude-team claude-ddb; do
	msg "Sync $variant config..."
	rsync -a --exclude='.DS_Store' --exclude='skills' --exclude='settings.json' --exclude='CLAUDE.md' \
		"$SCRIPT_DIR/claude/" "$HOME/.$variant/"
	"$SCRIPT_DIR/prune-retired.sh" "$SCRIPT_DIR/claude" "$HOME/.$variant"
done
# settings.json is merged, not copied: repository keys win, profile-only keys survive.
"$SCRIPT_DIR/sync-claude-settings.sh"

# Sync the three Codex profiles from the same source tree.
for variant in codex codex-team codex-api; do
	msg "Sync $variant config..."
	rsync -a --exclude='.DS_Store' --exclude='skills' --exclude='config.toml' --exclude='AGENTS.md' \
		${codex_rules:+--exclude="$codex_rules"} "$SCRIPT_DIR/codex/" "$HOME/.$variant/"
	if [ -n "$codex_rules" ]; then
		rm -f "$HOME/.$variant/rules/default.rules"
	fi
	# This also drops the old per-profile check-git-push.py; the Codex hook now
	# uses the shared copy in ~/.agents/hooks.
	"$SCRIPT_DIR/prune-retired.sh" "$SCRIPT_DIR/codex" "$HOME/.$variant"
done
# config.toml is rebuilt from the template plus the state Codex itself writes.
"$SCRIPT_DIR/sync-codex-config.sh"

# Compose public instructions with optional private instructions, once per sync.
"$SCRIPT_DIR/sync-instructions.sh"

# Idempotent; setup.sh runs it again beside the rexurrect plugin setup.
"$SCRIPT_DIR/install-rexurrect-launch.sh"
ok "Agent configuration synced"
