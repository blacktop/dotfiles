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

function info() {
    echo -e "$COL_BLUE[info]$COL_RESET - "$1
}
function running() {
    echo -en "$COL_YELLOW ⇒ $COL_RESET"$1": \n"
}

running "Configuring macOS"

if [[ $(xcode-select --version) ]]; then
  info "Xcode command tools already installed"
else
  running "Installing Xcode commandline tools"
  $(xcode-select --install)
fi

if [ -f "/Applications/Xcode-beta.app" ]; then
    running "Setting Xcode-beta.app as default Xcode"
    sudo xcode-select -p /Applications/Xcode-beta.app
fi

if [[ $(brew --version) ]] ; then
    running "Attempting to update Homebrew from version $(brew --version)"
    brew update
else
    running "Attempting to install Homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

brew update; brew upgrade --cask; brew cleanup || true

info "Homebrew Version"
brew --version

brew bundle --file=Brewfile || true

# git
running "Configuring git"
git config --global core.editor "code -w -n"
git config --global pull.rebase true
git config --global rebase.autoStash true

# python
running "Installing pip packages"
pip3 install -U pip setuptools virtualenv pipenv pytest nose pyflakes isort black --user

# VSCode
running "Setup VSCode"
vscode/setup.sh
# fish
running "Setup fish"
fish/setup.sh
# tmux
running "Setup tmux"
tmux/setup.sh
# neovim
running "Setup neovim"
nvim/setup.sh
# rust
running "Setup Rust"
rust/setup.sh

echo ✨ Done! ✨
