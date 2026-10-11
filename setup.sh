#!/usr/bin/env bash

set -e

DOTFILES_ROOT=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
# Apply opt-outs before the first installer or Homebrew invocation.
# shellcheck source=privacy/env.sh
. "$DOTFILES_ROOT/privacy/env.sh"

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
    echo -e "${COL_MAGENTA} ⇒ ${COL_RESET}$1"
}

function info() {
    echo -e "${COL_BLUE}[info]${COL_RESET}" "$1"
}

function has_gum_prompt_ui() {
    command -v gum >/dev/null 2>&1 && [[ -t 0 ]] && [[ -t 1 ]]
}

function confirm_step() {
    local prompt="$1"
    local env_name="${2:-}"
    local env_value=""
    local env_value_lower=""

    if [[ -n "$env_name" ]]; then
        env_value="${!env_name:-}"
        env_value_lower="$(printf '%s' "$env_value" | tr '[:upper:]' '[:lower:]')"
        case "$env_value_lower" in
        1 | true | yes | y)
            return 0
            ;;
        0 | false | no | n)
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

function initialize_xcode() {
    local developer_dir="$1"
    local xcodebuild_bin="$developer_dir/usr/bin/xcodebuild"

    # Standalone Command Line Tools do not include the full Xcode app.
    [[ -x "$xcodebuild_bin" ]] || return 0

    running "Accepting the Xcode license for $developer_dir"
    sudo env DEVELOPER_DIR="$developer_dir" "$xcodebuild_bin" -license accept
    if ! env DEVELOPER_DIR="$developer_dir" "$xcodebuild_bin" -checkFirstLaunchStatus >/dev/null 2>&1; then
        running "Completing Xcode first launch for $developer_dir"
        sudo env DEVELOPER_DIR="$developer_dir" "$xcodebuild_bin" -runFirstLaunch
    fi
}

function initialize_installed_xcodes() {
    local selected_dir
    local standard_dir="/Applications/Xcode.app/Contents/Developer"
    if ! selected_dir="$(xcode-select -p 2>/dev/null)"; then
        printf '%s\n' "Finish installing the Xcode Command Line Tools, then rerun ./setup.sh." >&2
        return 1
    fi

    initialize_xcode "$selected_dir"
    if [[ "$selected_dir" != "$standard_dir" ]]; then
        initialize_xcode "$standard_dir"
    fi
}

running "Configuring macOS"

if xcode-select -p >/dev/null 2>&1; then
    info "Xcode command tools already installed"
else
    running "Installing Xcode commandline tools"
    xcode-select --install
fi

if [[ "$(uname -m)" = "arm64" ]]; then
    running "Installing Rosetta 2"
    sudo softwareupdate --install-rosetta --agree-to-license
else
    info "Skipping Rosetta 2 install on non-Apple-silicon Mac"
fi

if [ -d "/Applications/Xcode-beta.app" ]; then
    if [ "$(xcode-select -p)" != "/Applications/Xcode-beta.app/Contents/Developer" ]; then
        running "Setting Xcode-beta.app as default Xcode"
        sudo xcode-select -s /Applications/Xcode-beta.app
    fi
fi

initialize_installed_xcodes

BREW_BIN="$(command -v brew || true)"
if [[ -n "$BREW_BIN" ]]; then
    running "Attempting to update Homebrew from version $("$BREW_BIN" --version)"
    "$BREW_BIN" update
else
    running "Attempting to install Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$(uname -m)" = "arm64" ]]; then
        BREW_BIN="/opt/homebrew/bin/brew"
    else
        BREW_BIN="/usr/local/bin/brew"
    fi
fi

eval "$("$BREW_BIN" shellenv)"

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

brew update
brew upgrade --cask
brew autoremove
brew cleanup --scrub --prune 0 || true

info "Homebrew Version"
brew --version

brew bundle --file=Brewfile || true
# The Brewfile can install or update the App Store's Xcode.
initialize_installed_xcodes
sh "$DOTFILES_ROOT/privacy/setup.sh"
brew cleanup --scrub --prune 0 || true

# Python tooling is managed by Brewfile/uv. Avoid mutating system Python.
info "Skipping system pip package install"

# git
git/setup.sh
# Visual Studio Code (optional)
if confirm_step "Install and configure Visual Studio Code?" "SETUP_VSCODE"; then
    "$DOTFILES_ROOT/vscode/setup.sh"
else
    info "Skipping Visual Studio Code setup (set SETUP_VSCODE=yes to enable non-interactively)"
fi
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
    echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Running 'macos/setup.sh'")"
    if [[ -t 0 && -t 1 ]]; then
        ./macos/setup.sh
    else
        ./macos/setup.sh --all
    fi
fi

# Offline profile
if confirm_step "Apply offline firewall (Tailscale-only + update window)?" "SETUP_OFFLINE_FIREWALL"; then
    echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Enabling offline pf profile")"
    ./offline/offline-firewall.sh enable
fi

echo ✨ Done! ✨
