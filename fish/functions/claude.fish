function claude -w claude -d 'Claude Code with its own GitHub token for sandboxed gh'
    set -fx RR_HARNESS ""
    set -fx RR_MODEL ""
    set -fx RR_EFFORT ""
    if set -q REX_SESSION[1] REX_BLOCK[1]; and test -n "$REX_SESSION"; and test -n "$REX_BLOCK"; and command -sq jq
        set -l rr_config
        switch "$CLAUDE_CONFIG_DIR"
            case '' "$HOME/.claude"
                set RR_HARNESS claude
                set rr_config "$HOME/.claude/settings.json"
            case "$HOME/.claude-ddb"
                set RR_HARNESS claude-ddb
                set rr_config "$HOME/.claude-ddb/settings.json"
        end
        if test -n "$RR_HARNESS"
            set RR_MODEL (jq -r '.model // ""' "$rr_config" 2>/dev/null)
            set RR_EFFORT (jq -r '.effortLevel // ""' "$rr_config" 2>/dev/null)
            set -l rr_argv $argv
            argparse --ignore-unknown 'model=' 'effort=' -- $argv; or return
            if set -q _flag_model
                set RR_MODEL "$_flag_model"
            end
            if set -q _flag_effort
                set RR_EFFORT "$_flag_effort"
            end
            set argv $rr_argv
        end
    end
    # gh reads GH_CONFIG_DIR instead of ~/.config/gh, which the sandbox denies; the
    # directory need not exist.
    set -fx GH_CONFIG_DIR $HOME/.config/gh-claude
    # Keep auto mode's classifier local, as it was with telemetry off before 2.1.282.
    # claude-team stays on the server-side check: the local classifier runs on
    # Sonnet, and that account may only use Mythos.
    if test "$CLAUDE_CONFIG_DIR" != "$HOME/.claude-team"
        set -fx CLAUDE_CODE_AUTO_MODE_SERVER 0
    end
    if set -l token (security find-generic-password -a $USER -s claude-gh-token -w 2>/dev/null)
        set -fx GH_TOKEN $token
    else
        echo 'claude: no claude-gh-token Keychain item, so gh is signed out (see ai/README.md)' >&2
    end
    command claude $argv
end
