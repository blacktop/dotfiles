function cu-attach --description 'Attach Container Use MCP to Claude or prep Zed launch env (idempotent CLAUDE.md)'
    if test (count $argv) -lt 1
        echo "usage: cu-attach (claude|zed)"; return 2
    end

    switch $argv[1]
    case claude
        set -l root (git rev-parse --show-toplevel 2>/dev/null)
        test -n "$root"; or begin; echo "cu-attach: run inside a git repo"; return 1; end
        cd $root

        if not type -q claude
            echo "cu-attach: missing 'claude' CLI"; return 127
        end
        if not type -q container-use
            echo "cu-attach: missing 'container-use' CLI"; return 127
        end
        if not type -q curl
            echo "cu-attach: missing 'curl'"; return 127
        end

        # 1) Register MCP only if not already present
        set -l have_mcp (claude mcp list 2>/dev/null | string match -r -q '(^|[[:space:]])container-use($|[[:space:]])'; and echo yes; or echo no)
        if test $have_mcp = no
            claude mcp add container-use -- container-use stdio
        end

        # 2) Idempotently manage the CLAUDE.md rules block
        set -l CLAUDE_MD "$root/CLAUDE.md"
        set -l RULES_URL "https://raw.githubusercontent.com/dagger/container-use/main/rules/agent.md"
        set -l tmp_rules (mktemp -t cu_rules)
        set -l tmp_block (mktemp -t cu_block)

        if not curl -fsSL $RULES_URL -o $tmp_rules
            echo "cu-attach: failed to download rules from $RULES_URL"
            rm -f $tmp_rules $tmp_block
            return 1
        end

        # Compose the managed block with clear sentinels
        printf "%s\n" "# BEGIN: CONTAINER-USE RULES (managed by cu-attach)" > $tmp_block
        cat $tmp_rules >> $tmp_block
        printf "\n# END: CONTAINER-USE RULES\n" >> $tmp_block

        # Ensure file exists
        test -e $CLAUDE_MD; or touch $CLAUDE_MD

        # Strip any existing managed block, then append the new one at the end
        set -l tmp_out (mktemp -t cu_claude)
        awk '
          BEGIN { skip=0 }
          /^# BEGIN: CONTAINER-USE RULES \(managed by cu-attach\)/ { skip=1; next }
          /^# END: CONTAINER-USE RULES/ { skip=0; next }
          skip==0 { print }
        ' $CLAUDE_MD > $tmp_out

        # add a separating newline if file not empty
        if test -s $tmp_out
            printf "\n" >> $tmp_out
        end
        cat $tmp_block >> $tmp_out
        mv $tmp_out $CLAUDE_MD

        rm -f $tmp_rules $tmp_block
        echo "✔ Claude wired to Container Use (CLAUDE.md updated idempotently)"

    case zed
        if not type -q zed
            echo "cu-attach: 'zed' CLI not found; open Zed manually and add the MCP server (container-use stdio) in Settings"; return 127
        end
        if not set -q _EXPERIMENTAL_DAGGER_RUNNER_HOST
            echo "warn: _EXPERIMENTAL_DAGGER_RUNNER_HOST not set; run 'cu-apple on' first if you use Apple containers"
        end
        env _EXPERIMENTAL_DAGGER_RUNNER_HOST=$_EXPERIMENTAL_DAGGER_RUNNER_HOST zed .
        echo "Tip: In Zed → Settings, add MCP server: command 'container-use', args ['stdio'] (or install the Container Use extension)"
    end
end
