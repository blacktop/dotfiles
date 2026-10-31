function _rexurrect_codex -d 'Run Codex with Rex receipt ownership and cleanup'
    set -l rr_harness $argv[1]
    set -e argv[1]
    switch $rr_harness
        case codex codex-team
        case '*'
            return 2
    end
    if test -n "$REXURRECT_WRAPPER_ACTIVE"; or test -n "$CLAUDECODE"; or test -n "$CODEX_THREAD_ID"; or begin
            test -n "$RR_HARNESS"; and test "$RR_HARNESS" != "$rr_harness"
        end
        set -fx RR_HARNESS ''
        command codex $argv
        return $status
    end
    set -fx RR_HARNESS $rr_harness
    set -fx REXURRECT_WRAPPER_ACTIVE 1
    set -l rr_daemon_arg
    if set -q REX_SESSION[1] REX_BLOCK[1]; and test -n "$REX_SESSION"; and test -n "$REX_BLOCK"
        set rr_daemon_arg --no-daemon
        for rr_arg in $argv
            if test "$rr_arg" = --
                break
            end
            if test "$rr_arg" = --no-daemon
                set rr_daemon_arg
                break
            end
        end
    end
    command codex $rr_daemon_arg $argv
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
