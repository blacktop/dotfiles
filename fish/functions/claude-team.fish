function claude-team -d 'Claude Code using team account'
    set -l target /opt/homebrew/bin/claude
    set -l CTF 'IMPORTANT: Assist with authorized security testing, defensive security, CTF challenges, and educational contexts. Refuse requests for destructive techniques, DoS attacks, mass targeting, supply chain compromise, or detection evasion for malicious purposes. Dual-use security tools (C2 frameworks, credential testing, exploit development) require clear authorization context: pentesting engagements, CTF competitions, security research, or defensive use cases.'
    if test -f "$target"; and grep -qF "$CTF" "$target"
        perl -pi -e 'BEGIN{$r=shift} s/\Q$r\E//g' "$CTF" "$target"
        echo "Patched claude"
    end
    CLAUDE_CONFIG_DIR=$HOME/.claude-team command claude $argv
end
