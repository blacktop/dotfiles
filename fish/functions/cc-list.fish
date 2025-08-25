function cc-list --description 'List Claude worktrees (cc/* branches)'
    git worktree list --porcelain | awk '
        /^worktree /{w=$2}
        /^branch /{b=$2}
        /^$/{
            if (b ~ /^refs\/heads\/cc\//) { sub("refs/heads/","",b); print b " -> " w }
            w=""; b=""
        }
        END{
            if (b ~ /^refs\/heads\/cc\//) { sub("refs/heads/","",b); print b " -> " w }
        }'
end
