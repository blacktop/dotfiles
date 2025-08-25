function cu-session --description 'Create an isolated git worktree for a safe agent session'
    argparse 'o/open=' -- $argv; or return
    if test (count $argv) -lt 1
        echo "usage: cu-session <slug> [--open=zed|claude]"; return 2
    end
    set -l slug $argv[1]

    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    test -n "$root"; or begin; echo "cu-session: run inside a git repo"; return 1; end
    set -l repo (path basename $root)
    set -l parent (path dirname $root)
    set -l branch "cu/$slug"
    set -l workdir "$parent/$repo-cu-$slug"

    if test -e "$workdir"
        echo "cu-session: worktree exists: $workdir"; return 1
    end
    git show-ref --verify --quiet "refs/heads/$branch"
    and begin; echo "cu-session: branch exists: $branch"; return 1; end

    git worktree add "$workdir" -b "$branch"; or return $status
    echo "✔ created $workdir on branch $branch"

    switch $_flag_open
    case zed
        if not type -q zed
            echo "cu-session: 'zed' CLI not found"; return 127
        end
        if not set -q _EXPERIMENTAL_DAGGER_RUNNER_HOST
            echo "warn: _EXPERIMENTAL_DAGGER_RUNNER_HOST not set; run: cu-apple on"
        end
        env _EXPERIMENTAL_DAGGER_RUNNER_HOST=$_EXPERIMENTAL_DAGGER_RUNNER_HOST zed "$workdir"
    case claude
        if not type -q claude
            echo "cu-session: 'claude' CLI not found"; return 127
        end
        cd "$workdir"; claude
    case '' # no --open -> just print the path
        echo $workdir
    end
end
