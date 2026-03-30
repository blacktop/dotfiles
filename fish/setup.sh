#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Fish")"

if [ "$SHELL" != "$(brew --prefix)/bin/fish" ]; then
    echo "$(gum style --bold --foreground "#FF9400" "[choose]") $(gum style --bold "Set fish as default shell?")"
    CHOICE=$(gum choose --cursor.foreground "#FF9400" --item.foreground "#F7BA00" "Yes" "No")
    if [[ "$CHOICE" == "Yes" ]]; then
        echo "$(gum style --bold --foreground "#BE05D0" "  -") Set fish as default shell..."
        echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells
        chsh -s "$(brew --prefix)/bin/fish"
    fi
fi

FISHER="$HOME/.config/fish/functions/fisher.fish"

if [ ! -f "$FISHER" ]; then
    echo "$(gum style --bold --foreground "#BE05D0" "  -") Downloading fisher..."
    curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
fi

echo "$(gum style --bold --foreground "#BE05D0" "  -") Installing fisher packages..."
# fish -c "fisher install catppuccin/fish"
# fish -c "fisher install vitallium/tokyonight-fish"
fish -c "fisher list | string match -q 'jethrokuan/fzf'; and fisher remove jethrokuan/fzf; true"
fish -c "fisher install PatrickF1/fzf.fish"
fish -c "fisher install jorgebucaran/autopair.fish"
fish -c "fisher install jorgebucaran/hydro"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Setup fish config (symlinks)..."
FISH_DIR="$(cd "$(dirname "$0")" && pwd)"
ln -sf "$FISH_DIR/config.fish" "$HOME/.config/fish/config.fish"
for f in "$FISH_DIR"/functions/*.fish; do
    ln -sf "$f" "$HOME/.config/fish/functions/$(basename "$f")"
done
mkdir -p "$HOME/.config/fish/themes"
for t in "$FISH_DIR"/themes/*; do
    ln -sf "$t" "$HOME/.config/fish/themes/$(basename "$t")"
done

# echo "$(gum style --bold --foreground "#BE05D0" "  -") Setup 🚀 starship prompt config..."
# cp -r $(dirname "$0")/config/starship.toml "$HOME/.config/starship.toml"
