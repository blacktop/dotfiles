function claude-team -w claude -d 'Claude Code using team account'
    _claude_patch_ctf
    CLAUDE_CONFIG_DIR=$HOME/.claude-team command claude $argv
end
