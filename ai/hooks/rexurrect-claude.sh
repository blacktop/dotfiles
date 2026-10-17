#!/bin/sh
set -eu

[ -n "${REX_SESSION:-}" ] && [ -n "${REX_BLOCK:-}" ] || exit 0
case "${RR_HARNESS:-}" in
claude)
	case "${CLAUDE_CONFIG_DIR:-}" in
	'' | "$HOME/.claude") ;;
	*) exit 0 ;;
	esac
	;;
claude-ddb)
	[ "${CLAUDE_CONFIG_DIR:-}" = "$HOME/.claude-ddb" ] || exit 0
	;;
*) exit 0 ;;
esac
command -v rexurrect >/dev/null 2>&1 || exit 0
rexurrect receipt set --help >/dev/null 2>&1 || exit 0

rr_server=${REXURRECT_SERVER:-"unix://$HOME/Library/Application Support/rex/server.sock"}
rr_state=${REXURRECT_STATE_DIR:-"$HOME/Library/Application Support/rexurrect"}
rr_event=$(
	head -c 65537
	printf '.'
)
rr_event=${rr_event%.}
rr_size=$(printf '%s' "$rr_event" | wc -c | tr -d '[:space:]')
if [ "$rr_size" -gt 65536 ]; then
	printf 'rexurrect: hook input exceeds 64 KiB\n' >&2
	exit 1
fi
rr_kind=$(printf '%s' "$rr_event" | jq -er '.hook_event_name | select(type == "string")')
rr_id=$(printf '%s' "$rr_event" | jq -er '.session_id | select(type == "string")')
case "$rr_kind" in
SessionStart)
	rr_model=$(printf '%s' "$rr_event" | jq -er '.model // "" | select(type == "string")')
	rr_model=${rr_model:-${RR_MODEL:-}}
	# Fable 5.1 has native 1M context. Preserve that exact model while fitting
	# S3's token grammar; other extended-context selectors must fail closed.
	[ "$rr_model" != 'claude-fable-5-1[1m]' ] || rr_model=claude-fable-5-1
	rexurrect receipt set --server "$rr_server" --state-dir "$rr_state" \
		--session "$REX_SESSION" --block "$REX_BLOCK" --harness "$RR_HARNESS" \
		--conversation "$rr_id" --model "$rr_model" \
		--effort "${RR_EFFORT:-}" >/dev/null
	;;
SessionEnd)
	rexurrect receipt clear --server "$rr_server" --state-dir "$rr_state" \
		--session "$REX_SESSION" --block "$REX_BLOCK" --conversation "$rr_id" >/dev/null
	;;
esac
