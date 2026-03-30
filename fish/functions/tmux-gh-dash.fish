function tmux-gh-dash -d "Opens a new, or the already existing, gh-dash tmux session."
    if not tmux has-session -t=gh-dash 2>/dev/null
        tmux new-session -A -d -s gh-dash -c "$HOME" fish -ilc 'gh dash'
    end

    tmux switch-client -t gh-dash
end
