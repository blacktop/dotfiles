#!/bin/sh
set -o errexit -o nounset

# NOTE: http://www.lazyvim.org

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Neovim")"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Setup neovim config..."

# required
mv ~/.config/nvim{,.bak} || true

# optional but recommended
mv ~/.local/share/nvim{,.bak} || true
mv ~/.local/state/nvim{,.bak} || true
mv ~/.cache/nvim{,.bak} || true

mkdir -p "$HOME/.config/nvim"

cp -r $(dirname "$0")/* "$HOME/.config/nvim/"
rm "$HOME/.config/nvim/setup.sh"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Update neovim plugins..."
nvim --headless "+Lazy! sync" +qa