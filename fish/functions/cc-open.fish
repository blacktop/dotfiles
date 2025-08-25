function cc-open --description 'Open a Claude worktree in Zed (fallback to cd)'
    if test (count $argv) -lt 1
        echo "usage: cc-open <feature-slug>"; return 2
    end
    set -l slug $argv[1]
    set -l root (git rev-parse --show-toplevel 2>/dev/null); or return 1
    set -l repo (basename $root)
    set -l parent (dirname $root)
    set -l dir "$parent/$repo-cc-$slug"
    if not test -d "$dir"
        echo "cc-open: no such worktree: $dir"; return 1
    end
    if type -q zed
        zed "$dir"
    else
        cd "$dir"; echo "cc-open: 'zed' not found; cd into $dir"
    end
end
