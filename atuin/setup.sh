#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Atuin")"

brew install --quiet atuin

echo "$(gum style --bold --foreground "#BE05D0" "  -") Configure Atuin..."
mkdir -p "$HOME/.config/atuin/themes"
cp "$(dirname "$0")/config.toml" "$HOME/.config/atuin/config.toml"
cp -r "$(dirname "$0")/themes/." "$HOME/.config/atuin/themes/"
