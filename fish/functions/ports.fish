function ports -d "a tool to easily see what's happening on your computer's ports"
    switch $argv[1]
        case 'ls'
            lsof -i -n -P
        case 'show'
            lsof -i :"$argv[2]" | tail -n 1
        case 'pid'
            lsof -i :"$argv[2]" | tail -n 1 | awk '{ print $2; }'
        case 'kill'
            kill -9 "$(ports pid "$argv[2]")"
    end
end