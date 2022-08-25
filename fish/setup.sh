#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Fish")"

if [ "$SHELL" != "$(brew --prefix)/bin/fish" ]; then
    echo "$(gum style --bold --foreground "#FF9400" "[choose]") $(gum style --bold "Set fish as default shell?)"
    CHOICE=$(gum choose --item.foreground 250 "Yes" "No")
    if [[ "$CHOICE" == "Yes" ]]; then
        echo "$(gum style --bold --foreground "#BE05D0" "  · ") $(gum style --bold "Set fish as default shell...")"
        echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells
        chsh -s "$(brew --prefix)/bin/fish"
    fi
fi

FISHER="$HOME/.config/fish/functions/fisher.fish"

if [ ! -f "$FISHER" ]; then
    echo "$(gum style --bold --foreground "#BE05D0" "  · ") $(gum style --bold "Downloading fisher...")"
    curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
fi

echo "$(gum style --bold --foreground "#BE05D0" "  · ") $(gum style --bold "Installing fisher packages...")"
fish -c "fisher install barnybug/docker-fish-completion"
fish -c "fisher install jethrokuan/fzf"
fish -c "fisher install derphilipp/enter-docker-fzf"
fish -c "fisher install pure-fish/pure"
fish -c "fisher install franciscolourenco/done"

echo "$(gum style --bold --foreground "#BE05D0" "  · ") $(gum style --bold "Setup fish config...")"
cp $(dirname "$0")/config.fish "$HOME/.config/fish/config.fish"
cp -r $(dirname "$0")/functions "$HOME/.config/fish/functions"