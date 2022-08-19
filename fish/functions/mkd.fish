function mkd --description 'Make directory and cd into it'
    mkdir -p $argv
    cd $argv;
end