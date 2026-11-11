#!/bin/sh
set -o errexit -o nounset

# ── Args ─────────────────────────────────────────────────────────────────────
case "${1:-}" in
--help | -h)
	cat <<EOF
Usage: $0

Safe to re-run. Installed settings are merged, not overwritten:
  ~/.claude*/settings.json  repository keys win; profile-only keys survive
  ~/.codex*/config.toml     rebuilt from the template plus the state Codex writes
                            (model, trusted projects, plugins, marketplaces, desktop)
Each changed file keeps its previous version beside it as <name>.bak.
EOF
	exit 0
	;;
esac

# ── Helpers ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(dirname "$0")"
# shellcheck source=privacy/env.sh
. "$SCRIPT_DIR/../privacy/env.sh"
# shellcheck source=ai/lib.sh
. "$SCRIPT_DIR/lib.sh"

install_npm_global_if_needed() {
	pkg="$1"
	cmd="$2"

	if ! command -v npm >/dev/null 2>&1; then
		warn "npm not found — skipping $pkg"
		return 0
	fi

	npm_installed=0
	if npm list -g "$pkg" --depth=0 >/dev/null 2>&1; then
		npm_installed=1
	fi

	old_version=""
	if command -v "$cmd" >/dev/null 2>&1; then
		old_version="$("$cmd" --version 2>/dev/null || true)"
	fi

	outdated=""
	outdated="$(npm outdated -g "$pkg" 2>/dev/null)" && outdated_status=0 || outdated_status=$?
	if [ "$npm_installed" = "1" ] && [ -n "$old_version" ] && [ -z "$outdated" ]; then
		if [ "$outdated_status" -eq 0 ]; then
			ok "$cmd $old_version up to date"
		else
			warn "Could not check $pkg updates; keeping $cmd $old_version"
		fi
		return 0
	fi

	msg "Install $pkg (npm)..."
	if npm install -g "$pkg"; then
		new_version=""
		if command -v "$cmd" >/dev/null 2>&1; then
			new_version="$("$cmd" --version 2>/dev/null || true)"
		fi
		if [ -n "$new_version" ] && [ "$old_version" != "$new_version" ]; then
			ok "$cmd: ${old_version:-not installed} -> $new_version"
		else
			ok "$pkg installed"
		fi
	else
		warn "Failed to install $pkg — continuing setup"
	fi
}

add_claude_marketplace() {
	variant="$1"
	marketplace="$2"
	source="$3"

	if claude plugin marketplace list --json 2>/dev/null | grep -q "\"name\": \"$marketplace\""; then
		return 0
	fi

	if claude plugin marketplace add "$source"; then
		return 0
	fi

	if claude plugin marketplace list --json 2>/dev/null | grep -q "\"name\": \"$marketplace\""; then
		return 0
	fi

	warn "$variant: failed to add $marketplace marketplace"
	return 1
}

install_claude_plugin() {
	variant="$1"
	plugin="$2"
	note="$3"

	if claude plugin install "$plugin" --scope user; then
		return 0
	fi

	if [ -n "$note" ]; then
		warn "$variant: failed to install $plugin ($note)"
	else
		warn "$variant: failed to install $plugin"
	fi
	return 1
}

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup AI CLI agents")"

# Install CLI agents
install_npm_global_if_needed "@anthropic-ai/claude-code" "claude"

install_npm_global_if_needed "@openai/codex" "codex"
# The standalone Codex app was discontinued; the ChatGPT app now hosts Codex.
# brew refuses to install over an app it did not put there, so skip when present.
if [ -d /Applications/ChatGPT.app ] || brew list --cask chatgpt >/dev/null 2>&1; then
	ok "ChatGPT app installed"
else
	msg "Install ChatGPT app (hosts the Codex GUI)..."
	brew install --quiet --cask chatgpt
fi

# Create config directories (including unified ~/.agents for hooks and skills)
mkdir -p "$HOME/.claude" "$HOME/.claude-team" "$HOME/.claude-ddb" "$HOME/.codex" "$HOME/.codex-team" "$HOME/.codex-api" "$HOME/.agents/hooks" "$HOME/.agents/skills"

# Per-host, opt-in and recorded in a local marker that sync.sh honours.
if [ -e "$HOME/.agents/yolo" ]; then
	warn "YOLO mode is on for this host; remove ~/.agents/yolo and re-run to harden"
elif [ -t 0 ] && gum confirm --default=false \
	"Run agents on this host in YOLO mode? This turns OFF the sandbox and approval prompts and allows git push. Guards stay for rm, sudo, disk tools, force-push, publishing and secret stores."; then
	: >"$HOME/.agents/yolo"
fi

# Hooks, settings, Codex config and instructions.
"$SCRIPT_DIR/sync.sh"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync skills..."
"$SCRIPT_DIR/sync-skills.sh"

# Rex's native installer adds its skill and startup hook to each account.
sh "$SCRIPT_DIR/../rex/setup.sh"

# Portable agent lifecycle integration, installed independently per account.
"$SCRIPT_DIR/install-rexurrect-launch.sh"
# A fresh setup may have just created ~/.local/bin/rex in the child installer.
PATH="$PATH:$HOME/.local/bin"
export PATH
if command -v rex >/dev/null 2>&1; then
	"$SCRIPT_DIR/setup-rexurrect.sh"
else
	warn 'Rex CLI not found; skipping rexurrect plugin setup'
fi

# Install Claude Code plugin marketplaces and plugins.
# `claude plugin` writes to $CLAUDE_CONFIG_DIR/plugins/, so each variant needs its own pass.
if command -v claude >/dev/null 2>&1; then
	echo "$(gum style --bold --foreground "#BE05D0" "  -") Install claude plugins..."
	for variant in claude claude-team claude-ddb; do
		config_dir="$HOME/.$variant"
		[ -d "$config_dir" ] || continue
		export CLAUDE_CONFIG_DIR="$config_dir"

		if add_claude_marketplace "$variant" "claude-plugins-official" "anthropics/claude-plugins-official"; then
			install_claude_plugin "$variant" "rust-analyzer-lsp@claude-plugins-official" ""
			install_claude_plugin "$variant" "gopls-lsp@claude-plugins-official" ""
			install_claude_plugin "$variant" "frontend-design@claude-plugins-official" ""
			install_claude_plugin "$variant" "skill-creator@claude-plugins-official" ""
			install_claude_plugin "$variant" "pr-review-toolkit@claude-plugins-official" ""
			install_claude_plugin "$variant" "plugin-dev@claude-plugins-official" ""
		else
			# code-improver's skill reviewer comes from this marketplace.
			exit 1
		fi

		if add_claude_marketplace "$variant" "openai-codex" "openai/codex-plugin-cc"; then
			install_claude_plugin "$variant" "codex@openai-codex" "/codex:review and /codex:rescue depend on it"
		fi

		# These skills require their parent workflows/agents. Install the full
		# packages only in Claude; ~/.agents/skills is also loaded by Codex.
		if add_claude_marketplace "$variant" "trailofbits" "trailofbits/skills"; then
			install_claude_plugin "$variant" "code-improver@trailofbits" "skill-improver requires its workflow and plugin-dev reviewer"
			install_claude_plugin "$variant" "c-review@trailofbits" "requires the C/C++ review workflow"
			install_claude_plugin "$variant" "audit-context-building@trailofbits" "requires its workflow and function-analyzer"
			install_claude_plugin "$variant" "dimensional-analysis@trailofbits" "requires its five specialist agents"
			install_claude_plugin "$variant" "differential-review@trailofbits" "includes its adversarial-modeler agent"
		else
			exit 1
		fi
	done
	unset CLAUDE_CONFIG_DIR
else
	gum style --faint "      ⚠ claude CLI not found, skipping plugin install"
fi

# Setup MCP servers (API keys → Keychain, register with Claude)
"$SCRIPT_DIR/mcp-setup.sh"

# Per-host, opt-in: root-owned policy files that no profile or agent can override.
# They forbid Claude's bypass mode, so a YOLO host must not have them.
if [ ! -e "$HOME/.agents/yolo" ]; then
	"$SCRIPT_DIR/host-lockdown/install.sh"
elif [ -e "/Library/Application Support/ClaudeCode/managed-settings.json" ]; then
	warn 'Host lockdown still blocks YOLO mode for Claude. Undo with: sudo rm "/Library/Application Support/ClaudeCode/managed-settings.json"'
fi

echo ""
echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "AI agents ready")"
gum style --faint "    Start new Claude and Codex sessions to load the changes."
