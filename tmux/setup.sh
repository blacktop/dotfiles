#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Tmux")"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "$(gum style --bold --foreground "#BE05D0" "  · ") $(gum style --bold "Downloading tmux-plugins manager...")"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "$(gum style --bold --foreground "#BE05D0" "  · ") $(gum style --bold "Configure tmux...")"
cp $(dirname "$0")/tmux.conf "$HOME/.tmux.conf"