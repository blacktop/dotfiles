if status is-interactive
    # Commands to run in interactive sessions can go here
end

fish_add_path -a $HOME/Library/Python/3.13/bin
fish_add_path -a $HOME/go/bin
fish_add_path -a /opt/homebrew/bin
fish_add_path -a /opt/homebrew/sbin
fish_add_path -a /opt/homebrew/opt/openjdk/bin
fish_add_path -a /opt/homebrew/opt/ruby/bin
fish_add_path -a $HOME/.cargo/bin
# fish_add_path -a $HOME/.modular/pkg/packages.modular.com_mojo/bin

if test -e /opt/homebrew/bin/brew
    eval $(/opt/homebrew/bin/brew shellenv)
end

# locals.fish is a home for anything machine specific
if test -e ~/.config/fish/locals.fish
    source ~/.config/fish/locals.fish
end

set -xg EDITOR (which code) -w

# STYLE #########################################
set fish_greeting
fish_config theme choose "TokyoNight Moon"
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
set -x HOMEBREW_CASK_OPTS '--appdir=/Applications --fontdir=~/Library/Fonts --require-sha'
set -x HOMEBREW_NO_INSECURE_REDIRECT 1

set -x TERM xterm-256color
set -x GREP_COLOR '1;33'
set -x CLICOLOR 1

# Prefer US English and use UTF-8.
set -x  LANG 'en_US.UTF-8'
set -x  LC_ALL 'en_US.UTF-8'

# Don’t clear the screen after quitting a manual page.
set -x  MANPAGER 'less -X'

# Avoid issues with `gpg` as installed via Homebrew.
# https://stackoverflow.com/a/42265848/96656
set -x GPG_TTY $(tty);

# fzf settings
function fish_user_key_bindings
    set -U FZF_LEGACY_KEYBINDINGS 0
    source $HOME/.config/fish/conf.d/fzf_key_bindings.fish
    source $HOME/.config/fish/functions/keys_bindings.fish
end

set -x FZF_COMPLETE 1
set -x FZF_REVERSE_ISEARCH_OPTS '--preview-window=up:10 --preview="echo {}" --height 100%'

set -x FZF_COMPLETE 1
set -x FZF_REVERSE_ISEARCH_OPTS '--preview-window=up:10 --preview="echo {}" --height 100%'
set -x FZF_LEGACY_KEYBINDINGS 0
set -x FZF_ENABLE_OPEN_PREVIEW 1
set -x FZF_PREVIEW_FILE_CMD "bat --color=always --theme=Nord2 --style=numbers --line-range=:500"
set -x FZF_TMUX 1
set -Ux FZF_DEFAULT_OPTS "\
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
# Catppuccin Mocha
# set -Ux FZF_DEFAULT_OPTS "\
# --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
# --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
# --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
# --color=selected-bg:#45475a \
# --border thinblock \
# --multi"

# zoxide
zoxide init fish | source

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
