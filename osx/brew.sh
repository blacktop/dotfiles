#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install Homebrew
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install brew packages
brew update

# Install GNU core utilities (those that come with OS X are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum
# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed --with-default-names
# Install Bash 4.
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
brew install bash
brew tap homebrew/versions
brew install bash-completion2

# Install `wget` with IRI support.
brew install wget --with-iri

brew install zsh
brew install exiftool
brew install tmux
brew install htop-osx
brew install jq
brew install openssl
brew install ctags

# Install other useful binaries.
brew install ack
# brew install dark-mode
brew install exiv2
brew install git
brew install git-lfs
brew install imagemagick --with-webp
brew install lua
brew install lynx
brew install p7zip
brew install pv
brew install rename
brew install speedtest_cli
brew install ssh-copy-id
brew install tree
brew install webkit2png

# Fix:
# https://stackoverflow.com/questions/19215590/why-cant-i-install-any-gems-on-my-mac
brew tap raggi/ale && brew install openssl-osx-ca
brew install vim --override-system-vim --with-lua --with-luajit
# Install python
brew install python python3 httpie
pip3 install --upgrade pip setuptools
pip install -U pip setuptools virtualenv virtualenvwrapper
# VirtualenvWrapper
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Devel
source /usr/local/bin/virtualenvwrapper.sh

# Install NodeJS
brew install node
sudo npm install bower -g

# Install Go
brew install go
mkdir -p ~/src/go
# Golang
export PATH=$PATH:/usr/local/opt/go/libexec/bin
export GOPATH=$HOME/src/go/
export PATH=$PATH:$GOPATH/bin
export GOROOT=/usr/local/Cellar/go/1.4.2/libexec

brew install bro yara volatility nmap
brew install docker boot2docker docker-machine docker-swarm docker-compose

# Install Brew Cask
brew install caskroom/cask/brew-cask
# Install Casks
brew cask install 1password
brew cask install adium

brew cask install atom
# Homebrew
export HOMEBREW_EDITOR=atom

brew cask install bettertouchtool
brew cask install cyberduck
brew cask install firefox
brew cask install flux
brew cask install github
brew cask install google-chrome
brew cask install gpgtools
brew cask install iterm2
brew cask install java
brew cask install licecap
brew cask install little-snitch
brew cask install onyx
brew cask install spectacle
brew cask install vagrant
brew cask install vault
brew cask install virtualbox
brew cask install wireshark
brew cask install xquartz
# brew cask install sublime-text

# Install fonts.
brew tap caskroom/fonts
fonts=(
    font-source-code-pro
    font-droid-sans-mono
    font-office-code-pro
    font-droid-sans
    font-dejavu-sans
    font-fira-mono
    font-inconsolata-dz
    font-roboto
    font-roboto-mono
)
echo "Installing fonts..."
brew cask install ${fonts[@]}

# Install more recent versions of some OS X tools.
brew install homebrew/dupes/grep
brew install homebrew/dupes/openssh
brew install homebrew/dupes/screen
brew install homebrew/php/php55 --with-gmp

# Install some CTF tools; see https://github.com/ctfs/write-ups.
# brew install aircrack-ng
# brew install bfg
# brew install binutils
# brew install binwalk
# brew install cifer
# brew install dex2jar
# brew install dns2tcp
# brew install fcrackzip
# brew install foremost
# brew install hashpump
# brew install hydra
# brew install john
# brew install knock
# brew install netpbm
# brew install nmap
# brew install pngcheck
# brew install socat
# brew install sqlmap
# brew install tcpflow
# brew install tcpreplay
# brew install tcptrace
# brew install ucspi-tcp # `tcpserver` etc.
# brew install xpdf
# brew install xz

# Remove outdated versions from the cellar.
brew cleanup
