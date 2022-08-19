#!/bin/sh
set -o errexit -o nounset

echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells
chsh -s "$(brew --prefix)/bin/fish"

# fisher for completions. 4.1.0
curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
fish -c "fisher install barnybug/docker-fish-completion"
fish -c "fisher install jethrokuan/fzf"
fish -c "fisher install derphilipp/enter-docker-fzf"
fish -c "fisher install pure-fish/pure"
fish -c "fisher install franciscolourenco/done"

cp $(dirname "$0")/config.fish "$HOME/.config/fish/config.fish"