function claude -w claude -d 'Claude Code with its own GitHub token for sandboxed gh'
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
