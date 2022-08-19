function grep --description 'Grep stuff with color'
    set -l param --color=auto
    command grep $param $argv
end