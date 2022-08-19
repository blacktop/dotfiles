function showFiles --description 'Show hidden files in Finder'
    defaults write com.apple.finder AppleShowAllFiles YES
    killall Finder /System/Library/CoreServices/Finder.app
end