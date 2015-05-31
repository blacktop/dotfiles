#!/bin/bash

git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

chsh -s `which zsh`

# Set up user profile
cat <<EOF >> $HOME/.zshrc

fileinfo(){
  for x in *; do echo "$(file $x) [md5: $(gmd5sum $x | awk '{ print $1 }')]"; done;
}

# VirtualenvWrapper
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Devel
source /usr/local/bin/virtualenvwrapper.sh

# Homebrew
export HOMEBREW_EDITOR=atom

# Golang
export PATH=$PATH:/usr/local/opt/go/libexec/bin
export GOPATH=$HOME/src/go/
export PATH=$PATH:$GOPATH/bin
export GOROOT=/usr/local/Cellar/go/1.4.2/libexec

# zsh movement
bindkey -e
bindkey '^[[1;9C' forward-word
bindkey '^[[1;9D' backward-word
bindkey '^[a' beginning-of-line
bindkey '^[e' end-of-line

# apt-get update EVRTing
alias apt-update='sudo apt-get update \
                  && sudo apt-get -y upgrade \
                  && sudo apt-get -y autoremove'

# Show human friendly numbers and colors
alias df='df -h'
alias ll='ls -alGh'
alias ls='ls -Gh'
alias du='du -h -d 2'

# zsh profile editing
alias ze='vim ~/.zshrc'
alias zr='source ~/.zshrc'

source ~/.yadr/zsh/prezto/modules/brew-cask/brew-cask.plugin.zsh
source ~/.yadr/zsh/prezto/modules/golang/golang.plugin.zsh
source ~/.yadr/zsh/prezto/modules/encode64/encode64.plugin.zsh
source ~/.yadr/zsh/prezto/modules/extract/extract.plugin.zsh
#source ~/.yadr/zsh/prezto/modules/docker/_docker
source ~/.yadr/zsh/prezto/modules/git-extras/git-extras.plugin.zsh

EOF

source ~/.zshrc
