

#!/usr/bin/env bash
echo Configuring mac

set -e

if [[ $(xcode-select --version) ]]; then
  echo Xcode command tools already installed
else
  echo "Installing Xcode commandline tools"
  $(xcode-select --install)
fi

if [[ $(brew --version) ]] ; then
    echo "Attempting to update Homebrew from version $(brew --version)"
    brew update
else
    echo "Attempting to install Homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

brew update; brew upgrade --cask; brew cleanup || true

echo Effective Homebrew version:
brew --version

brew bundle --file=Brewfile

# VSCode
ln -sf /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code $(brew --prefix)/bin/code

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

cp $(dirname "$0")/init/vscode_settings.json "$HOME/Library/Application\ Support/Code/User/settings.json"

# git
git config --global core.editor "code -w -n"
git config --global pull.rebase true
git config --global rebase.autoStash true

# fish
fish/setup.sh
# tmux
tmux/setup.sh
# neovim
nvim/setup.sh
# rust
rust/setup.sh

echo ✨ Done! ✨
