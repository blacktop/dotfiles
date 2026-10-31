function _rexurrect_claude -d 'Run Claude with Rex receipt ownership and cleanup'
    set -l rr_harness $argv[1]
    set -e argv[1]
    switch $rr_harness
        case claude claude-ddb
        case '*'
            return 2
    end
    if test -n "$REXURRECT_WRAPPER_ACTIVE"; or test -n "$CLAUDECODE"; or test -n "$CODEX_THREAD_ID"; or begin
            test -n "$RR_HARNESS"; and test "$RR_HARNESS" != "$rr_harness"
        end
        set -fx RR_HARNESS ''
        command claude $argv
        return $status
    end
    set -l rr_argv $argv
    set -fx RR_HARNESS $rr_harness
    set -fx REXURRECT_WRAPPER_ACTIVE 1
    set -fx RR_MODEL "$RR_MODEL"
    set -fx RR_EFFORT "$RR_EFFORT"
    argparse --ignore-unknown 'model=' 'effort=' -- $argv; or return
    if set -q _flag_model
        set RR_MODEL "$_flag_model"
    end
    if set -q _flag_effort
        set RR_EFFORT "$_flag_effort"
    end
    command claude $rr_argv
    set -l rr_status $status
    if set -q REX_SESSION[1] REX_BLOCK[1]; and test -n "$REX_SESSION"; and test -n "$REX_BLOCK"; and command -sq rexurrect
        set -l rr_server "unix://$HOME/Library/Application Support/rex/server.sock"
        set -l rr_state "$HOME/Library/Application Support/rexurrect"
        set -q REXURRECT_SERVER[1]; and set rr_server "$REXURRECT_SERVER"
        set -q REXURRECT_STATE_DIR[1]; and set rr_state "$REXURRECT_STATE_DIR"
        command rexurrect receipt clear --server "$rr_server" --state-dir "$rr_state" \
            --session "$REX_SESSION" --block "$REX_BLOCK" --harness "$rr_harness"; or return
    end
    return $rr_status
end
