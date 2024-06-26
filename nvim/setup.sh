#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Neovim")"

VIM_PLUG="$HOME/.vim/autoload/plug.vim"

if [ ! -f "$VIM_PLUG" ]; then
    echo "$(gum style --bold --foreground "#BE05D0" "  -") Downloading vim-plug..."
    curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "$(gum style --bold --foreground "#BE05D0" "  -") Setup neovim config..."
mkdir -p "$HOME/.config/nvim"
cp $(dirname "$0")/init.vim "$HOME/.config/nvim/init.vim"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Update neovim plugins..."
pip3 install --break-system-packages --user neovim
nvim +PlugUpdate +PlugUpgrade +qall