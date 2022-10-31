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
    echo -e "$COL_MAGENTA ⇒ $COL_RESET"$1
}

function info() {
    echo -e "$COL_BLUE[info]$COL_RESET" $1
}

running "Configuring macOS"

if [[ $(xcode-select --version) ]]; then
  info "Xcode command tools already installed"
else
  running "Installing Xcode commandline tools"
  $(xcode-select --install)
fi

if [ -d "/Applications/Xcode-beta.app" ]; then
    if [ "$(xcode-select -p)" != "/Applications/Xcode-beta.app/Contents/Developer" ]; then
        running "Setting Xcode-beta.app as default Xcode"
        sudo xcode-select -s /Applications/Xcode-beta.app
    fi
fi

if [[ $(brew --version) ]] ; then
    running "Attempting to update Homebrew from version $(brew --version)"
    brew update
else
    running "Attempting to install Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

brew update; brew upgrade --cask; brew cleanup || true

info "Homebrew Version"
brew --version

brew bundle --file=Brewfile || true

# python
running "Installing pip packages"
pip3 install -U pip setuptools virtualenv pipenv pytest nose pyflakes isort black --user

# git
git/setup.sh
# vscode
vscode/setup.sh
# fish
fish/setup.sh
# tmux
tmux/setup.sh
# neovim
nvim/setup.sh
# rust
rust/setup.sh

# Organize Launchpad
lporg load init/launchpad.yaml

# macOS
echo "$(gum style --bold --foreground "#FF9400" "[choose]") $(gum style --bold "Configure macOS defaults?")"
CHOICE=$(gum choose --cursor.foreground "#FF9400" --item.foreground "#F7BA00" "Yes" "No")
if [[ "$CHOICE" == "Yes" ]]; then
    echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Running 'config-osx.sh'")"
    exec ./config-osx.sh
fi

echo ✨ Done! ✨
