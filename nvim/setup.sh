#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Neovim")"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Setup neovim config..."
mkdir -p "$HOME/.config/nvim"
cp -r $(dirname "$0")/init.lua "$HOME/.config/nvim/init.lua"
cp -r $(dirname "$0")/after "$HOME/.config/nvim/"
cp -r $(dirname "$0")/lua "$HOME/.config/nvim/"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Update neovim plugins..."
nvim --headless "+Lazy! sync" +qa