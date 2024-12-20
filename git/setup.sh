#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Git")"

git config --global core.editor "code -w -n"
git config --global pull.rebase true
git config --global rebase.autoStash true

# echo "$(gum style --bold --foreground "#BE05D0" "  -") Install gh-dash..."
# gh extension install dlvhdr/gh-dash
# cp -r $(dirname "$0")/gh-dash/* "$HOME/.config/gh-dash/"