#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup VSCode")"

echo "$(gum style --bold --foreground "#BE05D0" "  · ") $(gum style --bold "Create VSCode cli 'code' alias")"
ln -sf /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code $(brew --prefix)/bin/code

echo "$(gum style --bold --foreground "#BE05D0" "  · ") $(gum style --bold "Install VSCode plugins...")"
code --install-extension alefragnani.Bookmarks --force
code --install-extension alexcvzz.vscode-sqlite --force
code --install-extension christian-kohler.path-intellisense --force
code --install-extension ms-python.python --force
code --install-extension ms-python.vscode-pylance --force
code --install-extension ms-toolsai.jupyter --force
code --install-extension Equinusocio.vsc-community-material-theme --force
code --install-extension equinusocio.vsc-material-theme-icons --force
code --install-extension golang.go --force
code --install-extension johnpapa.vscode-peacock --force
code --install-extension miguelsolorio.fluent-icons --force
code --install-extension ms-vscode.cpptools --force
code --install-extension ms-vscode.hexeditor --force
code --install-extension redhat.vscode-xml --force
code --install-extension redhat.vscode-yaml --force
code --install-extension rust-lang.rust-analyzer --force
code --install-extension serayuzgur.crates --force
code --install-extension tamasfe.even-better-toml --force
code --install-extension vadimcn.vscode-lldb --force
code --install-extension tinkertrain.theme-panda --force
code --install-extension wmaurer.change-case --force

echo "$(gum style --bold --foreground "#BE05D0" "  · ") $(gum style --bold "Configure VSCode settings...")"
cp $(dirname "$0")/vscode_settings.json "$HOME/Library/Application Support/Code/User/settings.json"
