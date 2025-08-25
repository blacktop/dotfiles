function cc-enter --description 'cd into a Claude worktree'
    if test (count $argv) -lt 1
        echo "usage: cc-enter <feature-slug>"; return 2
    end
    set -l slug $argv[1]
    set -l root (git rev-parse --show-toplevel 2>/dev/null); or return 1
    set -l repo (basename $root)
    set -l parent (dirname $root)
    set -l dir "$parent/$repo-cc-$slug"
    if test -d "$dir"
        cd "$dir"
    else
        echo "cc-enter: no such worktree: $dir"; return 1
    end
end
