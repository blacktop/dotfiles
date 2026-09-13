#!/usr/bin/env bash
# Render agent-session pressure for the tmux status bar.
#
# One-shot:
#   agent-sessions.sh [WARN ALARM]
# Watch mode keeps one tmux #() job alive and samples once per interval:
#   agent-sessions.sh --watch INTERVAL [WARN ALARM]
set -euo pipefail

usage() {
    printf 'Usage: %s [--watch INTERVAL] [WARN ALARM]\n' "${0##*/}" >&2
    exit 2
}

watch=false
interval=60
if [ "${1:-}" = "--watch" ]; then
    [ "$#" -ge 2 ] || usage
    watch=true
    interval=$2
    shift 2
fi

warn=${1:-32}
alarm=${2:-48}
[ "$#" -le 2 ] || usage

is_uint() {
    case "$1" in
    '' | *[!0-9]*) return 1 ;;
    esac
}

if ! is_uint "$interval" || ! is_uint "$warn" || ! is_uint "$alarm"; then
    usage
fi
[ "$interval" -gt 0 ] && [ "$warn" -gt 0 ] && [ "$alarm" -gt "$warn" ] ||
    usage

render() {
    count=$(
        ps -Ao comm= 2>/dev/null |
            /usr/bin/awk '
                {
                    name = $0
                    sub(/^.*\//, "", name)
                    sub(/^[[:space:]]+/, "", name)
                    sub(/[[:space:]]+$/, "", name)
                    if (name == "claude" || name == "claude.exe" || name == "codex")
                        count++
                }
                END { print count + 0 }
            '
    ) || {
        printf '\n'
        return
    }

    if [ "$count" -ge "$alarm" ]; then
        printf '#[fg=#eb6f92,bold]⛔ %s agents#[fg=#908caa,nobold] · \n' "$count"
    elif [ "$count" -ge "$warn" ]; then
        printf '#[fg=#f6c177,bold]⚠ %s agents#[fg=#908caa,nobold] · \n' "$count"
    else
        printf '\n'
    fi
}

if [ "$watch" = true ]; then
    while true; do
        render
        sleep "$interval"
    done
else
    render
fi
