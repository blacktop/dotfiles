# Run codex with full access sandbox mode
function cdx --description "Run codex exec with full sandbox access"
    codex -a on-request \
        --sandbox danger-full-access \
        exec \
        --skip-git-repo-check \
        $argv 2>/dev/null
end
