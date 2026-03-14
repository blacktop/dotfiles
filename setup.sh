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

function has_gum_prompt_ui() {
    command -v gum >/dev/null 2>&1 && [[ -t 0 ]] && [[ -t 1 ]]
}

function confirm_step() {
    local prompt="$1"
    local env_name="${2:-}"
    local env_value=""

    if [[ -n "$env_name" ]]; then
        env_value="${!env_name:-}"
        case "${env_value,,}" in
            1|true|yes|y)
                return 0
                ;;
            0|false|no|n)
                return 1
                ;;
        esac
    fi

    if has_gum_prompt_ui; then
        gum confirm "$prompt" \
            --prompt.foreground "#FF9400" \
            --selected.foreground "#230" \
            --selected.background "#FF9400" \
            --unselected.foreground "#F7BA00"
    else
        return 1
    fi
}

running "Configuring macOS"

if [[ $(xcode-select --version) ]]; then
  info "Xcode command tools already installed"
else
  running "Installing Xcode commandline tools"
  $(xcode-select --install)
fi

running "Installing Rosetta 2"
sudo softwareupdate --install-rosetta --agree-to-license

if [ -d "/Applications/Xcode-beta.app" ]; then
    if [ "$(xcode-select -p)" != "/Applications/Xcode-beta.app/Contents/Developer" ]; then
        running "Setting Xcode-beta.app as default Xcode"
        sudo xcode-select -s /Applications/Xcode-beta.app
    fi
fi

if [[ $(/opt/homebrew/bin/brew --version) ]] ; then
    running "Attempting to update Homebrew from version $(/opt/homebrew/bin/brew --version)"
    /opt/homebrew/bin/brew update
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
pip3 install --break-system-packages -U pip setuptools virtualenv pipenv pytest nose pyflakes isort black --user

# git
git/setup.sh
# vscode
vscode/setup.sh
# fish
fish/setup.sh
# atuin
atuin/setup.sh
# tmux
tmux/setup.sh
# rust
rust/setup.sh
# neovim
nvim/setup.sh || true
# ghostty
ghostty/setup.sh
# zed
zed/setup.sh
# bat
bat/setup.sh
# ollama
# ollama/setup.sh
# LM Studio (large model downloads; opt-in only)
if confirm_step "Install LM Studio and download local models? This downloads large models." "SETUP_LMSTUDIO"; then
    lmstudio/lms.sh
else
    info "Skipping LM Studio setup (set SETUP_LMSTUDIO=yes to enable non-interactively)"
fi
# zig
# zig/setup.sh
# AI CLI agents (Claude Code, Codex, etc.)
ai/setup.sh

# Create Dev folders
mkdir -p ~/Developer/Github
mkdir -p ~/Developer/Work
mkdir -p ~/Developer/XCode

if [[ $(sw_vers -productVersion | cut -d . -f 1) -lt 26 ]]; then
  # Organize Launchpad/Dock (pre macOS 26.x)
  brew install blacktop/tap/lporg
  lporg load --config init/lporg.yml --no-backup --yes
fi

# macOS
if confirm_step "Configure macOS defaults?" "SETUP_MACOS_DEFAULTS"; then
    echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Running 'config-osx.sh'")"
    exec ./config-osx.sh
fi

# Offline profile
if confirm_step "Apply offline firewall (Tailscale-only + update window)?" "SETUP_OFFLINE_FIREWALL"; then
    echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Enabling offline pf profile")"
    ./offline/offline-firewall.sh enable
fi

echo ✨ Done! ✨
