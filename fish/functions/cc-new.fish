function cc-new --description 'Create a Claude Code worktree and start a session'
    if test (count $argv) -lt 1
        echo "usage: cc-new <feature-slug>"
        return 2
    end
    set -l slug $argv[1]

    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$root"
        echo "cc-new: not inside a Git repo"; return 1
    end

    set -l repo (basename $root)
    set -l parent (dirname $root)
    set -l branch "cc/$slug"
    set -l workdir "$parent/$repo-cc-$slug"

    if test -e "$workdir"
        echo "cc-new: worktree already exists: $workdir"; return 1
    end
    git show-ref --verify --quiet "refs/heads/$branch"
    if test $status -eq 0
        echo "cc-new: branch already exists: $branch"; return 1
    end

    git worktree add "$workdir" -b "$branch"; or return $status
    cd "$workdir"
    if type -q claude
        claude
    else
        echo "cc-new: 'claude' CLI not found; opened $workdir"
    end
end
