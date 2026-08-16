function _xcode_diff_label --argument-names app
    set -l plist $app/Contents/version.plist
    set -l short (/usr/bin/plutil -extract CFBundleShortVersionString raw $plist 2>/dev/null)
    set -l build (/usr/bin/plutil -extract ProductBuildVersion raw $plist 2>/dev/null)
    if test -n "$short" -a -n "$build"
        printf '%s-%s\n' $short $build
    else if test -n "$short"
        printf '%s\n' $short
    else
        string replace -r '\.app$' '' -- (path basename $app)
    end
end

function _xcode_diff_sdk --argument-names app platform
    set -l sdks $app/Contents/Developer/Platforms/$platform.platform/Developer/SDKs
    set -l base $sdks/$platform.sdk
    if not test -d $base
        return 1
    end
    # Versioned SDK dirs are symlinks to <Platform>.sdk; prefer them so diff titles show versions.
    set -l sdk_version (/usr/bin/plutil -extract Version raw $base/SDKSettings.plist 2>/dev/null)
    if test -n "$sdk_version" -a -d "$sdks/$platform$sdk_version.sdk"
        printf '%s\n' $sdks/$platform$sdk_version.sdk
    else
        printf '%s\n' $base
    end
end

function _xcode_diff_pid --argument-names app
    for pid in (command pgrep -x Xcode 2>/dev/null)
        set -l exe (command ps -p $pid -o comm= 2>/dev/null)
        if test -n "$exe" -a (path resolve -- "$exe") = "$app/Contents/MacOS/Xcode"
            printf '%s\n' $pid
            return 0
        end
    end
    return 1
end

# Snapshots one Xcode's agent skills into $dest. Progress goes to stderr so callers can
# use the return code alone. `agent skills export` talks to a running Xcode over the MCP
# bridge and ignores DEVELOPER_DIR, so the instance is pinned by PID (a wrong PID hangs).
function _xcode_diff_snapshot --argument-names app dest refresh dry_run
    if test -d $dest -a "$refresh" = 0
        printf 'skills: reusing %s\n' $dest >&2
        return 0
    end

    set -l pid (_xcode_diff_pid $app)
    if test -z "$pid"
        if test -d $dest
            printf 'skills: %s is not running, reusing %s\n' $app $dest >&2
            return 0
        end
        printf 'Error: %s must be running to export its skills\n' $app >&2
        printf 'Hint: open -a %s   # then re-run\n' $app >&2
        return 1
    end

    set -l agent $app/Contents/Developer/usr/bin/agent
    if not test -x $agent
        printf 'Error: %s has no agent tool (needs Xcode 26.6 or newer)\n' $app >&2
        return 1
    end

    if test "$dry_run" = 1
        printf 'skills: MCP_XCODE_PID=%s %s skills export --output-dir %s --replace-existing\n' \
            $pid $agent $dest >&2
        return 0
    end

    printf 'skills: exporting %s (pid %s) -> %s\n' $app $pid $dest >&2
    command mkdir -p (path dirname $dest); or return 1
    env MCP_XCODE_PID=$pid $agent skills export --output-dir $dest --replace-existing >&2
    if not test -d $dest; or test (count (command ls -A $dest 2>/dev/null)) -eq 0
        printf 'Error: skills export produced nothing for %s\n' $app >&2
        return 1
    end
end

function _xcode_diff_compare --argument-names label left right dry_run
    printf '\n%s\n  A: %s\n  B: %s\n' $label $left $right
    if test "$dry_run" = 1
        printf '  COMPARE_FOLDERS=DIFF code %s %s\n' $left $right
        return 0
    end
    env COMPARE_FOLDERS=DIFF code $left $right
end

function xcode-diff --description 'Diff a new Xcode against an older one (agent skills + platform SDK)'
    set -l usage 'Usage: xcode-diff [--old <Xcode.app>] [--new <Xcode.app>] [--platform <name>] [--skills] [--sdk] [--refresh] [--archive <dir>] [--dry-run]'

    set -l old_app /Applications/Xcode.app
    set -l new_app /Applications/Xcode-beta.app
    set -l platform iPhoneOS
    set -l archive ~/Developer/Mine/blacktop/xcode-skills
    set -l want_skills 0
    set -l want_sdk 0
    set -l refresh 0
    set -l dry_run 0

    set -l i 1
    while test $i -le (count $argv)
        set -l arg $argv[$i]
        switch $arg
            case -h --help
                printf '%s\n\n' $usage
                printf 'Options:\n'
                printf '  --old <Xcode.app>  Older Xcode to diff from (default: /Applications/Xcode.app)\n'
                printf '  --new <Xcode.app>  Newer Xcode to diff to (default: /Applications/Xcode-beta.app)\n'
                printf '  --platform <name>  SDK platform (default: iPhoneOS); accepts ios, macos, tvos,\n'
                printf '                     watchos, visionos, driverkit, and their simulator variants\n'
                printf '  --skills           Only diff exported agent skills\n'
                printf '  --sdk              Only diff platform SDKs\n'
                printf '  --refresh          Re-export skills even when a snapshot already exists\n'
                printf '  --archive <dir>    Skills snapshot root (default: ~/Developer/Mine/blacktop/xcode-skills)\n'
                printf '  --dry-run          Print resolved paths and commands without running them\n'
                printf '  -h, --help         Show this help\n\n'
                printf 'With neither --skills nor --sdk, both diffs run. Each diff opens in VS Code via\n'
                printf 'the moshfeu.compare-folders extension (COMPARE_FOLDERS=DIFF).\n\n'
                printf 'Skills snapshots land in <archive>/<version>-<build> and are reused once taken.\n'
                printf '`agent skills export` reads from a running Xcode over the MCP bridge, so each\n'
                printf 'side must be open the first time it is snapshotted — snapshot an Xcode while you\n'
                printf 'still have it, then later diffs against it are free.\n'
                return 0
            case --old --new --platform --archive
                set -l opt $arg
                set i (math $i + 1)
                if test $i -gt (count $argv); or string match -q -- '-*' $argv[$i]
                    printf 'Error: %s requires a value\n' $opt >&2
                    return 64
                end
                switch $opt
                    case --old
                        set old_app $argv[$i]
                    case --new
                        set new_app $argv[$i]
                    case --platform
                        set platform $argv[$i]
                    case --archive
                        set archive $argv[$i]
                end
            case --skills
                set want_skills 1
            case --sdk
                set want_sdk 1
            case --refresh
                set refresh 1
            case --dry-run
                set dry_run 1
            case '*'
                printf 'Error: unexpected argument %s\n' $arg >&2
                printf '%s\n' $usage >&2
                return 64
        end
        set i (math $i + 1)
    end

    if test $want_skills -eq 0 -a $want_sdk -eq 0
        set want_skills 1
        set want_sdk 1
    end

    if not command -sq code
        printf 'Error: code (VS Code CLI) not found on PATH\n' >&2
        return 127
    end

    set old_app (path resolve -- $old_app)
    set new_app (path resolve -- $new_app)
    for app in $old_app $new_app
        if not test -d $app/Contents/Developer
            printf 'Error: %s is not an Xcode.app (no Contents/Developer)\n' $app >&2
            return 66
        end
    end
    if test $old_app = $new_app
        printf 'Error: --old and --new resolve to the same Xcode (%s)\n' $old_app >&2
        return 64
    end

    switch (string lower -- $platform)
        case ios iphoneos
            set platform iPhoneOS
        case iossimulator iphonesimulator
            set platform iPhoneSimulator
        case macos macosx osx
            set platform MacOSX
        case tvos appletvos
            set platform AppleTVOS
        case tvossimulator appletvsimulator
            set platform AppleTVSimulator
        case watchos
            set platform WatchOS
        case watchossimulator watchsimulator
            set platform WatchSimulator
        case visionos xros
            set platform XROS
        case visionossimulator xrsimulator
            set platform XRSimulator
        case driverkit
            set platform DriverKit
    end

    set -l old_label (_xcode_diff_label $old_app)
    set -l new_label (_xcode_diff_label $new_app)
    printf 'old: %s (%s)\nnew: %s (%s)\n' $old_label $old_app $new_label $new_app

    # A skills failure must not cancel the SDK diff — they are independent.
    set -l rc 0
    if test $want_skills -eq 1
        set -l old_snap $archive/$old_label
        set -l new_snap $archive/$new_label
        if _xcode_diff_snapshot $old_app $old_snap $refresh $dry_run
            and _xcode_diff_snapshot $new_app $new_snap $refresh $dry_run
            _xcode_diff_compare "skills: $old_label -> $new_label" $old_snap $new_snap $dry_run
        else
            printf 'skills: diff skipped\n' >&2
            set rc 1
        end
    end

    if test $want_sdk -eq 1
        set -l old_sdk (_xcode_diff_sdk $old_app $platform)
        if test -z "$old_sdk"
            printf 'Error: no %s SDK in %s\n' $platform $old_app >&2
            return 66
        end
        set -l new_sdk (_xcode_diff_sdk $new_app $platform)
        if test -z "$new_sdk"
            printf 'Error: no %s SDK in %s\n' $platform $new_app >&2
            return 66
        end
        _xcode_diff_compare "sdk: $platform" $old_sdk $new_sdk $dry_run
    end

    return $rc
end
