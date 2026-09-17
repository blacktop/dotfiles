function ipsw-diff --description 'Diff two IPSWs with comprehensive analysis'
    set -l usage 'Usage: ipsw-diff [--block] [--device <product-type|board>] <old.ipsw> <new.ipsw> [--kdk <old.kdk> <new.kdk>]'

    # Parse arguments
    set -l ipsw_old ''
    set -l ipsw_new ''
    set -l kdk_old ''
    set -l kdk_new ''
    set -l device ''
    set -l block 0
    set -l i 1

    while test $i -le (count $argv)
        set -l arg $argv[$i]
        switch $arg
            case -h --help
                printf '%s\n\n' $usage
                printf 'Positional arguments:\n'
                printf '  old.ipsw    The older IPSW to compare from\n'
                printf '  new.ipsw    The newer IPSW to compare to\n\n'
                printf 'Options:\n'
                printf '  --block            Wait for the inputs to appear and finish\n'
                printf '                     downloading instead of erroring when missing.\n'
                printf '                     Waits forever, so check the path for typos.\n'
                printf '                     Ctrl-C to give up.\n'
                printf '  --kdk <old> <new>  KDK kernel paths for symbolication (must provide both)\n'
                printf '  --device <value>   Device product type or board (e.g. Mac18,5)\n'
                printf '  -h, --help         Show this help\n\n'
                printf 'Output directory: %s\n' ~/Developer/Mine/blacktop/ipsw-diffs
                return 0
            case --block
                set block 1
            case --device '--device=*'
                if test "$arg" = --device
                    set i (math $i + 1)
                    set device $argv[$i]
                else
                    set device (string replace -- '--device=' '' "$arg")
                end
                if test -z "$device"; or string match -q -- '-*' "$device"
                    printf 'Error: --device requires a product type or board\n' >&2
                    return 64
                end
            case --kdk
                set i (math $i + 1)
                if test $i -gt (count $argv)
                    printf 'Error: --kdk requires two arguments\n' >&2
                    return 64
                end
                set kdk_old $argv[$i]
                set i (math $i + 1)
                if test $i -gt (count $argv)
                    printf 'Error: --kdk requires two arguments\n' >&2
                    return 64
                end
                set kdk_new $argv[$i]
            case '-*'
                printf 'Error: unknown option %s\n' $arg >&2
                printf '%s\n' $usage >&2
                return 64
            case '*'
                if test -z "$ipsw_old"
                    set ipsw_old $arg
                else if test -z "$ipsw_new"
                    set ipsw_new $arg
                else
                    printf 'Error: unexpected argument %s\n' $arg >&2
                    printf '%s\n' $usage >&2
                    return 64
                end
        end
        set i (math $i + 1)
    end

    # Validate required arguments
    if test -z "$ipsw_old" -o -z "$ipsw_new"
        printf 'Error: two IPSW files are required\n' >&2
        printf '%s\n' $usage >&2
        return 64
    end

    # Validate KDK arguments (must have both or neither)
    if test -n "$kdk_old" -a -z "$kdk_new"
        printf 'Error: --kdk requires both old and new KDK paths\n' >&2
        return 64
    end
    if test -z "$kdk_old" -a -n "$kdk_new"
        printf 'Error: --kdk requires both old and new KDK paths\n' >&2
        return 64
    end

    # Check ipsw is available
    if not command -sq ipsw
        printf 'Error: ipsw command not found on PATH\n' >&2
        return 127
    end

    set -l inputs $ipsw_old $ipsw_new
    if test -n "$kdk_old"
        set -a inputs $kdk_old $kdk_new
    end

    if test $block -eq 1
        # Block until every input has landed and stopped growing
        for input in $inputs
            __ipsw_diff_await $input
        end
    else
        # Fail fast on typos rather than handing a bad path to ipsw
        set -l missing
        for input in $inputs
            if not test -f "$input"
                set -a missing $input
            end
        end
        if test (count $missing) -gt 0
            for input in $missing
                printf 'Error: no such file: %s\n' $input >&2
            end
            printf 'Pass --block to wait for it to download.\n' >&2
            return 66
        end
    end

    # Build command
    set -l cmd ipsw diff \
        --output ~/Developer/Mine/blacktop/ipsw-diffs \
        --markdown \
        --ent \
        --fw \
        --launchd \
        --loc \
        --feat \
        --strs \
        --files \
        --starts \
        --sandbox \
        --signatures ~/Developer/Mine/blacktop/symbolicator/kernel \
        --block-list '__TEXT.__info_plist' \
        --block-list '__AUTH_CONST.__auth_ptr' \
        --block-list '__DATA.__bss' \
        --ignore-build-timestamps \
        $ipsw_old \
        $ipsw_new

    if test -n "$device"
        set -a cmd --device "$device"
    end

    # Add KDK args if provided
    if test -n "$kdk_old"
        set -a cmd --kdk $kdk_old --kdk $kdk_new
    end

    # Run the command
    printf 'Running: %s\n' (string join ' ' -- $cmd)
    $cmd
end

function __ipsw_diff_await --description 'Block until a file exists and has stopped growing'
    set -l path $argv[1]
    set -l interval 5
    set -l waited 0
    set -l announced 0
    set -l size 0

    while true
        set size 0
        set -l stat_out (stat -f '%z %m' -- "$path" 2>/dev/null | string split ' ')
        if test (count $stat_out) -eq 2
            set size $stat_out[1]
            # A `.download` sidecar means `ipsw download` is still writing it;
            # a recent mtime means something else is (browser, rsync, cp).
            set -l idle (math (date +%s) - $stat_out[2])
            if test $size -gt 0 -a $idle -ge $interval; and not test -e "$path.download"
                break
            end
        end

        if test $announced -eq 0
            printf 'Waiting for %s\n' $path
            set announced 1
        end
        __ipsw_diff_progress $waited $size
        sleep $interval
        set waited (math $waited + $interval)
    end

    if test $announced -eq 1; and isatty stdout
        printf '\r\e[K'
    end
    printf 'Ready: %s (%s)\n' $path (__ipsw_diff_human $size)
end

function __ipsw_diff_progress --description 'Render the waiting status line'
    set -l waited $argv[1]
    set -l size $argv[2]
    set -l line (printf '  %02d:%02d  %s' (math "floor($waited / 60)") (math "$waited % 60") (__ipsw_diff_human $size))

    if isatty stdout
        printf '\r\e[K%s' $line
    else if test (math "$waited % 60") -eq 0
        printf '%s\n' $line
    end
end

function __ipsw_diff_human --description 'Format bytes as MB/GB'
    set -l bytes $argv[1]
    if test $bytes -lt 1073741824
        printf '%s MB' (math -s1 "$bytes / 1048576")
    else
        printf '%s GB' (math -s2 "$bytes / 1073741824")
    end
end
