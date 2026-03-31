fish_add_path --global -a $HOME/Library/Python/3.13/bin
fish_add_path --global -a $HOME/Library/Python/3.14/bin
fish_add_path --global -a $HOME/go/bin
fish_add_path --global -a /opt/homebrew/bin
fish_add_path --global -a /opt/homebrew/sbin
fish_add_path --global -a /opt/homebrew/opt/openjdk/bin
fish_add_path --global -a /opt/homebrew/opt/ruby/bin
fish_add_path --global -a /opt/homebrew/opt/llvm/bin
fish_add_path --global -a $HOME/.cargo/bin
fish_add_path --global -a $HOME/.bun/bin
fish_add_path --global -a $HOME/.local/bin
fish_add_path --global -a $HOME/.lmstudio/bin # LM Studio CLI (lms)
fish_add_path --global -a $HOME/.orbstack/bin
# fish_add_path --global -a $HOME/.modular/pkg/packages.modular.com_mojo/bin

if test -e /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

# locals.fish is a home for anything machine specific
if test -f "$HOME/.config/fish/locals.fish"
    source "$HOME/.config/fish/locals.fish"
end

# Secure Enclave SSH key provider (needed for git commit signing + SSH auth)
set -gx SSH_SK_PROVIDER /usr/lib/ssh-keychain.dylib

if command -q zed
    set -gx EDITOR "zed --wait"
    set -gx VISUAL "zed --wait"
else if command -q code
    set -gx EDITOR "code -w"
    set -gx VISUAL "code -w"
end

# STYLE #########################################
set fish_greeting
if test -f "$HOME/.config/fish/themes/TokyoNight Moon.theme"
    while read -l name value
        if string match -qr '^(#|$)' -- "$name"
            continue
        end
        set -g $name $value
    end < "$HOME/.config/fish/themes/TokyoNight Moon.theme"
end
# Prompt
set hydro_color_pwd brcyan
set hydro_color_git brmagenta
set hydro_color_error brred
set hydro_color_prompt brgreen
set hydro_color_duration bryellow

# alias #########################################
alias l 'eza -l -g --git'
# Shows all timestamps in their full glory
alias lf 'eza -guUmhl --git --time-style long-iso'
alias lt 'eza -guUmhl -T --hyperlink --git --time-style long-iso'
alias ta 'tmux new -A -s default'

# homebrew
set -gx HOMEBREW_CASK_OPTS "--appdir=/Applications --fontdir=$HOME/Library/Fonts --require-sha"
set -gx HOMEBREW_NO_INSECURE_REDIRECT 1

set -gx GREP_COLOR '1;33'
set -gx CLICOLOR 1

# Prefer US English and use UTF-8.
set -gx LANG 'en_US.UTF-8'

# Don’t clear the screen after quitting a manual page.
set -gx MANPAGER 'less -X'

# Avoid issues with `gpg` as installed via Homebrew.
# https://stackoverflow.com/a/42265848/96656
if status is-interactive
    set -gx GPG_TTY (tty)
end

# fzf settings
function fish_user_key_bindings
    if functions -q fzf_configure_bindings
        fzf_configure_bindings
    else if functions -q fzf_key_bindings
        fzf_key_bindings
    end

    if test -f "$HOME/.config/fish/functions/keys_bindings.fish"
        source "$HOME/.config/fish/functions/keys_bindings.fish"
    end
end

set -gx FZF_DEFAULT_OPTS "\
    --color=bg:#16161e \
    --color=bg+:#283457 \
    --color=border:#27a1b9 \
    --color=fg:#c0caf5 \
    --color=gutter:#16161e \
    --color=header:#ff9e64 \
    --color=hl:#2ac3de \
    --color=hl+:#2ac3de \
    --color=info:#545c7e \
    --color=marker:#ff007c \
    --color=pointer:#ff007c \
    --color=prompt:#2ac3de \
    --color=query:#c0caf5:regular \
    --color=scrollbar:#27a1b9 \
    --color=separator:#ff9e64 \
    --color=spinner:#ff007c \
    --border thinblock \
    --multi"
set -gx fzf_preview_file_cmd "bat --color=always --theme=Nord2 --style=numbers --line-range=:500"
set -gx fzf_history_opts "--preview-window=down:3:hidden:wrap --bind '?:toggle-preview'"
# Catppuccin Mocha
# set -gx FZF_DEFAULT_OPTS "\
# --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
# --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
# --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
# --color=selected-bg:#45475a \
# --border thinblock \
# --multi"

# zoxide
if command -q zoxide
    zoxide init fish | source
end

# shell history
if command -q atuin
    atuin init fish --disable-ctrl-r | source
end

function expand-dot-to-parent-directory-path -d 'expand ... to ../.. etc'
    # Get commandline up to cursor
    set -l cmd (commandline --cut-at-cursor)

    # Match last line
    switch $cmd[-1]
        case '*..'
            commandline --insert '/.'
        case '*'
            commandline --insert '.'
    end
end

bind . 'expand-dot-to-parent-directory-path'
