function claude-ddb -w claude -d 'Claude Code using ddb account'
    _claude_patch_ctf
    CLAUDE_CONFIG_DIR=$HOME/.claude-ddb command claude $argv
end
