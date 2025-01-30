#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒") $(gum style --bold "Setup Zed")"

brew install --cask zed

echo "$(gum style --bold --foreground "#BE05D0" "  -") Configure Zed settings..."
mkdir -p "$HOME/.config/zed"
cp $(dirname "$0")/config/config.json "$HOME/.config/zed/settings.json"
