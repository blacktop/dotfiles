#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup AI CLI agents")"

# Install CLI agents via Homebrew
# echo "$(gum style --bold --foreground "#BE05D0" "  -") Install claude-code..."
# brew install --quiet claude-code

# echo "$(gum style --bold --foreground "#BE05D0" "  -") Install codex..."
# brew install --quiet openai-codex

# echo "$(gum style --bold --foreground "#BE05D0" "  -") Install gemini-cli..."
# brew install --quiet gemini-cli

# Install skill dependencies
echo "$(gum style --bold --foreground "#BE05D0" "  -") Install ralph-tui..."
bun install -g ralph-tui 2>/dev/null || echo "$(gum style --faint "      ⚠ bun not found, skipping ralph-tui")"

# Create config directories
mkdir -p "$HOME/.claude" "$HOME/.codex" "$HOME/.gemini" "$HOME/.agents"

SCRIPT_DIR="$(dirname "$0")"

# Copy agent config files
echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync claude config..."
rsync -a --exclude='.DS_Store' "$SCRIPT_DIR/claude/" "$HOME/.claude/"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync codex config..."
rsync -a --exclude='.DS_Store' "$SCRIPT_DIR/codex/" "$HOME/.codex/"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync gemini config..."
rsync -a --exclude='.DS_Store' "$SCRIPT_DIR/gemini/" "$HOME/.gemini/"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync skills..."
"$SCRIPT_DIR/sync-skills.sh"

# Install Gemini CLI extensions
echo "$(gum style --bold --foreground "#BE05D0" "  -") Install gemini extensions..."
"$SCRIPT_DIR/gemini/install-extensions.sh"
