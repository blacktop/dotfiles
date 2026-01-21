#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup AI CLI agents")"

mkdir -p "$HOME/.claude" "$HOME/.codex"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Copy statusline.sh..."
cp "$(dirname "$0")/statusline.sh" "$HOME/.claude/statusline.sh"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync skills..."
"$(dirname "$0")/sync-skills.sh"
