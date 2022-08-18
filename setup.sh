

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
code --install-extension --force Equinusocio.vsc-community-material-theme
code --install-extension --force equinusocio.vsc-material-theme-icons
code --install-extension --force golang.go
code --install-extension --force johnpapa.vscode-peacock
code --install-extension --force miguelsolorio.fluent-icons
code --install-extension --force ms-vscode.cpptools
code --install-extension --force ms-vscode.hexeditor
code --install-extension --force redhat.vscode-xml
code --install-extension --force redhat.vscode-yaml
code --install-extension --force rust-lang.rust-analyzer
code --install-extension --force serayuzgur.crates
code --install-extension --force tamasfe.even-better-toml
code --install-extension --force vadimcn.vscode-lldb
code --install-extension --force tinkertrain.theme-panda
code --install-extension --force wmaurer.change-case

# git
git config --global core.editor "code -w -n"
git config --global pull.rebase true
git config --global rebase.autoStash true

# fish
bash fish/setup.sh
# tmux
bash tmux/setup.sh
# neovim
bash nvim/setup.sh
# rust
bash rust/setup.sh

echo ✨ Done! ✨
