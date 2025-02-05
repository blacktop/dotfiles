#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Tmux")"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "$(gum style --bold --foreground "#BE05D0" "  -") Downloading tmux-plugins manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "$(gum style --bold --foreground "#BE05D0" "  -") Configure tmux..."
cp $(dirname "$0")/tmux.conf "$HOME/.tmux.conf"
TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" ~/.tmux/plugins/tpm/bin/install_plugins
# Fix nord-tmux plugin hostname
cp $(dirname "$0")/nord/* ~/.tmux/plugins/nord-tmux/src