function hideFiles --description 'Hide hidden files in Finder'
    defaults write com.apple.finder AppleShowAllFiles NO
    killall Finder /System/Library/CoreServices/Finder.app
end