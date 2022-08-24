

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

brew bundle --file=Brewfile || true

# git
git config --global core.editor "code -w -n"
git config --global pull.rebase true
git config --global rebase.autoStash true

# python
pip3 install -U pip setuptools virtualenv pipenv pytest nose pyflakes isort black --user

# VSCode
vscode/setup.sh
# fish
fish/setup.sh
# tmux
tmux/setup.sh
# neovim
nvim/setup.sh
# rust
rust/setup.sh

echo ✨ Done! ✨
