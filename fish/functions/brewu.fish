function brewu -d "Update All the things"
  brew update
  brew upgrade
  brew cleanup
  brew doctor
  brew cu -a
end
