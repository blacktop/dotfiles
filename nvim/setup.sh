#!/bin/sh
set -o errexit -o nounset

VIM_PLUG="$HOME/.vim/autoload/plug.vim"

if [ ! -f "$VIM_PLUG" ]; then
    echo "Downloading vim-plug..."
    curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

mkdir -p "$HOME/.config/nvim"
cp $(dirname "$0")/init.vim "$HOME/.config/nvim/init.vim"

pip3 install --user neovim

nvim +PlugUpdate +PlugUpgrade +qall