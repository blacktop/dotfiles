function fcd -d "Fuzzy change directory"
    set -l searchdir $HOME
    if set -q argv[1]
        set searchdir $argv[1]
    end

    set -l destdir (find "$searchdir" \( ! -regex '.*/\..*' \) ! -name __pycache__ -type d | fzf)
    if test -n "$destdir"
        cd "$destdir"
    end
end
