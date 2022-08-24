#!/bin/sh
set -o errexit -o nounset

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

cp $(dirname "$0")/tmux.conf "$HOME/.tmux.conf"