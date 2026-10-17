function _rexurrect_codex -d 'Run an explicit Codex resume with a Rex receipt'
    set -l rr_harness $argv[1]
    set -e argv[1]
    switch $rr_harness
        case codex codex-team
        case '*'
            return 2
    end

    set -l rr_id
    set -l rr_server "unix://$HOME/Library/Application Support/rex/server.sock"
    set -l rr_state "$HOME/Library/Application Support/rexurrect"
    set -q REXURRECT_SERVER[1]; and set rr_server "$REXURRECT_SERVER"
    set -q REXURRECT_STATE_DIR[1]; and set rr_state "$REXURRECT_STATE_DIR"
    if test (count $argv) -ge 2; and test "$argv[1]" = resume; and string match -rq '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' -- "$argv[2]"; and set -q REX_SESSION[1] REX_BLOCK[1]; and test -n "$REX_SESSION"; and test -n "$REX_BLOCK"; and command -sq rexurrect; and command rexurrect receipt set --help >/dev/null 2>&1
        set rr_id "$argv[2]"
        set -l rr_model ""
        set -l rr_effort ""
        set -l rr_argv $argv
        argparse --ignore-unknown 'm/model=' 'c/config=+' -- $argv[3..-1]; or return
        if set -q _flag_model
            set rr_model "$_flag_model"
        end
        for rr_config in $_flag_config
            if string match -q 'model_reasoning_effort=*' -- "$rr_config"
                set rr_effort (string replace -r '^model_reasoning_effort="?([^\\"]+)"?$' '$1' -- "$rr_config")
            end
        end
        set argv $rr_argv
        command rexurrect receipt set --server "$rr_server" --state-dir "$rr_state" \
            --session "$REX_SESSION" --block "$REX_BLOCK" --harness "$rr_harness" \
            --conversation "$rr_id" --model "$rr_model" --effort "$rr_effort"; or return
    end

    command codex $argv
    set -l rr_status $status
    if test -n "$rr_id"
        command rexurrect receipt clear --server "$rr_server" --state-dir "$rr_state" \
            --session "$REX_SESSION" --block "$REX_BLOCK" --conversation "$rr_id"; or return
    end
    return $rr_status
end
