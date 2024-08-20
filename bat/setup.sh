#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup bat 🦇")"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Setup bat config..."
mkdir -p "$HOME/.config/bat/syntaxes" "$HOME/.config/bat/themes"
cp -r $(dirname "$0")/syntaxes "$HOME/.config/bat"
cp -r $(dirname "$0")/themes "$HOME/.config/bat"

bat cache --build