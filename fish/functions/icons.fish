function icons -d "Translates program names to icons, so we an use them in our tmux config."
    switch $argv[1]
        case ack fd find fzf grep rg
            echo 
        case atop htop top
            echo 
        case bash fish zsh sh ash
            echo 
        case bat cat
            echo 
        case clx
            echo 
        case cp duplicate
            echo 
        case mv
            echo 󰉒
        case curl http pint lynx wget w3m
            echo 
        case docker docker-compose podman
            echo 
        case lf ls nnn ranger lsd
            echo 
        case elixir mix
            echo 
        case gh gh-dash
            echo 
        case git lazygit tig
            echo 
        case glow
            echo 
        case go goreleaser
            echo 
        case java mvn
            echo 
        case less more
            echo 
        case lua
            echo 
        case man
            echo 
        case nano pico
            echo 
        case node npm yarn
            echo 
        case 'nix*'
            echo 󱄅
        case vim vi
            echo 
        case nvim
            echo 
        case python pip
            echo 
        case rm
            echo 
        case rsync
            echo 
        case ruby irb
            echo 
        case scp ssh
            echo 󰣀
        case sleep
            echo 
        case sudo
            echo 
        case tail
            echo 
        case task make
            echo 
        case tmux
            echo 
        case youtube-dl
            echo 
        case '*'
            echo $argv[1]
    end
end