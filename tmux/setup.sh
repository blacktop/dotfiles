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

# Retire the managed assistant session tracker and its OpenCode lifecycle plugin.
legacy_assistant_plugin="$HOME/.tmux/plugins/tmux-assistant-resurrect"
legacy_opencode_tracker="$HOME/.config/opencode/plugins/session-tracker.js"
if [ -L "$legacy_opencode_tracker" ] &&
    [ "$(readlink "$legacy_opencode_tracker")" = "$legacy_assistant_plugin/hooks/opencode-session-track.js" ]; then
    /usr/bin/trash "$legacy_opencode_tracker"
fi
if [ -d "$legacy_assistant_plugin" ]; then
    /usr/bin/trash "$legacy_assistant_plugin"
fi

# Status-bar helper scripts (e.g. Apple Music now-playing) referenced by #()
mkdir -p "$HOME/.config/tmux/scripts"
cp "$script_dir"/scripts/* "$HOME/.config/tmux/scripts/"
TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" ~/.tmux/plugins/tpm/bin/install_plugins
# Fix nord-tmux plugin hostname
if [ -d "$HOME/.tmux/plugins/nord-tmux/src" ]; then
    cp "$script_dir"/nord/* "$HOME/.tmux/plugins/nord-tmux/src"
fi
