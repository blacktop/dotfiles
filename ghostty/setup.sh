#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Ghostty")"

brew install --build-from-source $(dirname "$0")/ghostty.rb

mkdir -p "$HOME/.config/ghostty"
cp $(dirname "$0")/config "$HOME/.config/ghostty/config"