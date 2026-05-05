function ipsw-diff --description 'Diff two IPSWs with comprehensive analysis'
    set -l usage 'Usage: ipsw-diff <old.ipsw> <new.ipsw> [--kdk <old.kdk> <new.kdk>]'

    # Parse arguments
    set -l ipsw_old ''
    set -l ipsw_new ''
    set -l kdk_old ''
    set -l kdk_new ''
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
                printf '  --kdk <old> <new>  KDK kernel paths for symbolication (must provide both)\n'
                printf '  -h, --help         Show this help\n\n'
                printf 'Output directory: ../ipsw-diffs (relative to current directory)\n'
                return 0
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

    # Build command
    set -l cmd ipsw diff \
        --output ~/Developer/Mine/blacktop/ipsw-diffs \
        --markdown \
        --ent \
        --fw \
        --launchd \
        --feat \
        --strs \
        --files \
        --starts \
        --sandbox \
        --signatures ~/Developer/Mine/blacktop/symbolicator/kernel \
        --block-list '__TEXT.__info_plist' \
        --block-list '__AUTH_CONST.__auth_ptr' \
        $ipsw_old \
        $ipsw_new

    # Add KDK args if provided
    if test -n "$kdk_old"
        set -a cmd --kdk $kdk_old --kdk $kdk_new
    end

    # Run the command
    printf 'Running: %s\n' (string join ' ' -- $cmd)
    $cmd
end
