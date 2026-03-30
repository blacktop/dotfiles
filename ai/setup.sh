#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup AI CLI agents")"

# Install CLI agents via Homebrew
echo "$(gum style --bold --foreground "#BE05D0" "  -") Install claude-code..."
brew install --quiet claude-code

echo "$(gum style --bold --foreground "#BE05D0" "  -") Install codex..."
brew install --quiet codex codex-app

echo "$(gum style --bold --foreground "#BE05D0" "  -") Install gemini-cli..."
brew install --quiet gemini-cli

# Install skill dependencies
echo "$(gum style --bold --foreground "#BE05D0" "  -") Install ralph-tui..."
bun install -g ralph-tui 2>/dev/null || echo "$(gum style --faint "      ⚠ bun not found, skipping ralph-tui")"

# Create config directories (including unified ~/.agents for skills)
mkdir -p "$HOME/.claude" "$HOME/.codex" "$HOME/.gemini" "$HOME/.agents/skills"

SCRIPT_DIR="$(dirname "$0")"

# Copy agent config files
echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync claude config..."
rsync -a --exclude='.DS_Store' --exclude='skills' "$SCRIPT_DIR/claude/" "$HOME/.claude/"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync codex config..."
rsync -a --exclude='.DS_Store' --exclude='skills' "$SCRIPT_DIR/codex/" "$HOME/.codex/"

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
else
    echo "$(gum style --faint "      ⚠ claude CLI not found, skipping plugin install")"
fi

# Setup MCP servers (API keys → Keychain, register with Claude + Codex)
"$SCRIPT_DIR/mcp-setup.sh"
