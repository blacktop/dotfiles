#!/bin/sh
set -o errexit -o nounset

VIM_PLUG="$HOME/.vim/autoload/plug.vim"

if [ ! -f "$VIM_PLUG" ]; then
    echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Downloading vim-plug...")"
    curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup neovim config...")"
mkdir -p "$HOME/.config/nvim"
cp $(dirname "$0")/init.vim "$HOME/.config/nvim/init.vim"

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Update neovim plugins...")"
pip3 install --user neovim
nvim +PlugUpdate +PlugUpgrade +qall