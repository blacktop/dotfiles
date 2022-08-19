function ll --description 'List contents of directory using long format'
    set -l param --color=auto
    command ls -lah $param $argv
end