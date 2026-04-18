#!/bin/sh
set -o errexit -o nounset

# ── Args / env ───────────────────────────────────────────────────────────────
# Default: preserve existing user-mutable configs (settings.json, config.toml).
# Use --force or AI_FORCE_SYNC=1 to overwrite them with the dotfile template.
FORCE_SYNC="${AI_FORCE_SYNC:-0}"
case "${1:-}" in
--force | -f) FORCE_SYNC=1 ;;
--help | -h)
    cat <<EOF
Usage: $0 [--force|-f]

Idempotent by default — re-running preserves your customised:
  ~/.claude/settings.json
  ~/.codex/config.toml

Use --force (or AI_FORCE_SYNC=1) to overwrite those with the dotfile template.
Static content (CLAUDE.md, agents/, commands/, prompts/, statusline.sh) and
managed MCP blocks always sync.
EOF
    exit 0
    ;;
esac

# ── Helpers ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(dirname "$0")"
. "$SCRIPT_DIR/lib.sh"

# Sync a user-mutable file. Skip if dest exists unless FORCE_SYNC=1.
# Args: description, src, dst
sync_user_file() {
    desc="$1" src="$2" dst="$3"
    if [ -f "$dst" ] && [ "$FORCE_SYNC" != "1" ]; then
        if cmp -s "$src" "$dst"; then
            ok "$desc up to date"
        else
            warn "Skipped $desc (exists & differs — review with: diff '$src' '$dst')"
            warn "    re-run with --force to overwrite"
        fi
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    ok "Wrote $desc"
}

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup AI CLI agents")"
[ "$FORCE_SYNC" = "1" ] && warn "FORCE mode: user-mutable configs will be overwritten"

# Install CLI agents
msg "Install claude-code (npm)..."
npm install -g @anthropic-ai/claude-code

msg "Install codex (npm CLI + brew GUI cask)..."
npm install -g @openai/codex
brew install --quiet codex-app

msg "Install gemini-cli..."
brew install --quiet gemini-cli

# Install skill dependencies
echo "$(gum style --bold --foreground "#BE05D0" "  -") Install ralph-tui..."
bun install -g ralph-tui 2>/dev/null || echo "$(gum style --faint "      ⚠ bun not found, skipping ralph-tui")"

# Create config directories (including unified ~/.agents for skills)
mkdir -p "$HOME/.claude" "$HOME/.claude-team" "$HOME/.codex" "$HOME/.gemini" "$HOME/.agents/skills"

# Sync claude + claude-team from the same source tree (settings.json gated by FORCE_SYNC)
for variant in claude claude-team; do
    msg "Sync $variant config..."
    rsync -a --exclude='.DS_Store' --exclude='skills' --exclude='settings.json' \
        "$SCRIPT_DIR/claude/" "$HOME/.$variant/"
    sync_user_file "$variant settings.json" \
        "$SCRIPT_DIR/claude/settings.json" "$HOME/.$variant/settings.json"
done

msg "Sync codex config..."
rsync -a --exclude='.DS_Store' --exclude='skills' --exclude='config.toml' \
    "$SCRIPT_DIR/codex/" "$HOME/.codex/"
# Codex TOML doesn't expand env vars — render ${HOME} placeholders before installing.
codex_tmp=$(mktemp -t codex-config.toml)
sed "s|\${HOME}|$HOME|g" "$SCRIPT_DIR/codex/config.toml" >"$codex_tmp"
sync_user_file "codex config.toml" "$codex_tmp" "$HOME/.codex/config.toml"
rm -f "$codex_tmp"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync gemini config..."
rsync -a --exclude='.DS_Store' --exclude='skills' "$SCRIPT_DIR/gemini/" "$HOME/.gemini/"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync skills..."
"$SCRIPT_DIR/sync-skills.sh"

# Install Gemini CLI extensions
echo "$(gum style --bold --foreground "#BE05D0" "  -") Install gemini extensions..."
"$SCRIPT_DIR/gemini/install-extensions.sh"

# Install Claude Code plugin marketplaces and plugins
if command -v claude >/dev/null 2>&1; then
    echo "$(gum style --bold --foreground "#BE05D0" "  -") Install claude plugins..."
    if ! claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null; then
        echo "$(gum style --bold --foreground "#FF9400" "  ⚠") Failed to add claude-plugins-official marketplace"
    fi
    if ! claude plugin install pr-review-toolkit@claude-plugins-official 2>/dev/null; then
        echo "$(gum style --bold --foreground "#FF9400" "  ⚠") Failed to install pr-review-toolkit (/review-pr and /fix-issue depend on it)"
    fi
    if ! claude plugin marketplace add openai/codex-plugin-cc 2>/dev/null; then
        echo "$(gum style --bold --foreground "#FF9400" "  ⚠") Failed to add openai/codex-plugin-cc marketplace"
    fi
    if ! claude plugin install codex@openai-codex 2>/dev/null; then
        echo "$(gum style --bold --foreground "#FF9400" "  ⚠") Failed to install codex plugin (/codex:review, /codex:rescue)"
    fi
else
    echo "$(gum style --faint "      ⚠ claude CLI not found, skipping plugin install")"
fi

# Setup MCP servers (API keys → Keychain, register with Claude + Codex)
"$SCRIPT_DIR/mcp-setup.sh"
