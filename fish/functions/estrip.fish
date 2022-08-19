function estrip --description 'Strip file metadata'
    exiftool -all= $argv
end