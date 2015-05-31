#!/bin/bash

# Install base tool set
sudo apt-get install -y zsh git-core vim build-essential python python-dev python-distribute wget curl tree unzip \
  && sudo -E easy_install pip \
  && sudo update-alternatives --set editor /usr/bin/vim.basic

# Add blacktop user and add to sudoers
if ! getent passwd blacktop; then
  sudo adduser blacktop
  sudo /usr/sbin/visudo
fi

# Configure zsh
$(which zsh) zsh_config.sh
