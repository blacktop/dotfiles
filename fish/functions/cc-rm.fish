function cc-rm --description 'Remove a Claude worktree and delete its branch'
    if test (count $argv) -lt 1
        echo "usage: cc-rm <feature-slug>"
        return 2
    end
    set -l slug $argv[1]

    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$root"
        echo "cc-rm: not inside a Git repo"; return 1
    end

    set -l repo (basename $root)
    set -l parent (dirname $root)
    set -l branch "cc/$slug"
    set -l workdir "$parent/$repo-cc-$slug"

    git worktree remove -f "$workdir"
    set -l rm_status $status
    git branch -D "$branch" 2>/dev/null
    if test $rm_status -ne 0
        echo "cc-rm: failed to remove $workdir"; return $rm_status
    end
end
