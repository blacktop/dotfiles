#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Tmux")"
script_dir=$(dirname "$0")

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "$(gum style --bold --foreground "#BE05D0" "  -") Downloading tmux-plugins manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

echo "$(gum style --bold --foreground "#BE05D0" "  -") Configure tmux..."
cp "$script_dir/tmux.conf" "$HOME/.tmux.conf"
TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" ~/.tmux/plugins/tpm/bin/install_plugins
# Fix nord-tmux plugin hostname
if [ -d "$HOME/.tmux/plugins/nord-tmux/src" ]; then
    cp "$script_dir"/nord/* "$HOME/.tmux/plugins/nord-tmux/src"
fi
