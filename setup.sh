#!/usr/bin/env bash

set -e

# Colors
export ESC_SEQ="\x1b["
export COL_RESET=$ESC_SEQ"39;49;00m"
export COL_RED=$ESC_SEQ"31;01m"
export COL_GREEN=$ESC_SEQ"32;01m"
export COL_YELLOW=$ESC_SEQ"33;01m"
export COL_BLUE=$ESC_SEQ"34;01m"
export COL_MAGENTA=$ESC_SEQ"35;01m"
export COL_CYAN=$ESC_SEQ"36;01m"

function running() {
    echo -en "$COL_YELLOW ⇒ $COL_RESET"$1": "
}

running Configuring mac

if [[ $(xcode-select --version) ]]; then
  echo Xcode command tools already installed
else
  echo "Installing Xcode commandline tools"
  $(xcode-select --install)
fi

if [ -f "/Applications/Xcode-beta.app" ]; then
    echo "Setting Xcode-beta.app as default Xcode"
    sudo xcode-select -p /Applications/Xcode-beta.app
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
