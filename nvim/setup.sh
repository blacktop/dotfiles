#!/bin/sh
set -o errexit -o nounset

VIM_PLUG="$HOME/.vim/autoload/plug.vim"

if [ ! -f "$VIM_PLUG" ]; then
    running "Downloading vim-plug..."
    curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

running "Setup neovim config..."
mkdir -p "$HOME/.config/nvim"
cp $(dirname "$0")/init.vim "$HOME/.config/nvim/init.vim"

running "Update neovim plugins..."
pip3 install --user neovim
nvim +PlugUpdate +PlugUpgrade +qall