function claude-hax -w claude -d 'Patch and run claude'
    _claude_patch_ctf
    CLAUDE_LAUNCH_NAME=claude-hax claude $argv
end
