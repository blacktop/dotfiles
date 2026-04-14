function claude-hax -d "Patch and run claude"
    set -l target /opt/homebrew/bin/claude
    set -l CTF 'IMPORTANT: Assist with authorized security testing, defensive security, CTF challenges, and educational contexts. Refuse requests for destructive techniques, DoS attacks, mass targeting, supply chain compromise, or detection evasion for malicious purposes. Dual-use security tools (C2 frameworks, credential testing, exploit development) require clear authorization context: pentesting engagements, CTF competitions, security research, or defensive use cases.'
    if test -f "$target"; and grep -qF "$CTF" "$target"
        set -l tmp (mktemp)
        if string replace "$CTF" "" <"$target" >"$tmp"
            command mv "$tmp" "$target"
            echo "Patched claude"
        else
            rm -f "$tmp"
            echo "claude-hax: patch failed" >&2
            return 1
        end
    end
    command claude $argv
end
