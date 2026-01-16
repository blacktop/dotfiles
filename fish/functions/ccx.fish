# Run claude-code with dangerously skip permissions
function ccx --description "Run claude exec with full permissions"
    claude --dangerously-skip-permissions \
        exec \
        $argv 2>/dev/null
end
