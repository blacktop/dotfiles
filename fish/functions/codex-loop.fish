function codex-loop --description 'Queue a prompt into a Codex session on an interval, 8 times'
    if test (count $argv) -lt 2 -o (count $argv) -gt 3
        printf 'Usage: codex-loop THREAD [INTERVAL] "prompt"\n' >&2
        printf 'THREAD is a Codex session UUID or exact session name.\n' >&2
        printf 'INTERVAL is a sleep duration like 90s, 30m, or 1h (default 30m).\n' >&2
        return 2
    end

    set -l thread $argv[1]
    set -l prompt $argv[-1]
    set -l interval 30m
    if test (count $argv) -eq 3
        set interval $argv[2]
    end

    if not string match -qr '^\d+(\.\d+)?[smhd]?$' -- $interval
        printf 'codex-loop: invalid interval %s (want e.g. 90s, 30m, 1h)\n' $interval >&2
        return 2
    end

    set -l ticks 8

    for tick in (seq $ticks)
        codex queue --thread $thread --message $prompt
        or return

        if test $tick -lt $ticks
            sleep $interval
            or return
        end
    end
end
