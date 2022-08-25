#!/bin/sh
set -o errexit -o nounset

if [ "$SHELL" == "$(brew --prefix)/bin/fish" ]; then
    echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells
    chsh -s "$(brew --prefix)/bin/fish"
fi

FISHER="$HOME/.config/fish/functions/fisher.fish"

if [ ! -f "$FISHER" ]; then
    running "Downloading fisher..."
    curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
fi

running "Installing fisher packages..."
fish -c "fisher install barnybug/docker-fish-completion"
fish -c "fisher install jethrokuan/fzf"
fish -c "fisher install derphilipp/enter-docker-fzf"
fish -c "fisher install pure-fish/pure"
fish -c "fisher install franciscolourenco/done"

running "Setup fish config..."
cp $(dirname "$0")/config.fish "$HOME/.config/fish/config.fish"
cp -r $(dirname "$0")/functions "$HOME/.config/fish/functions"