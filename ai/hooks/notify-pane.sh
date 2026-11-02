#!/bin/bash
set -euo pipefail

# Claude and Codex hook: post a macOS notification naming the terminal pane an agent
# runs in, so a spoken alert heard from another room can be traced to its pane.
#
#   notify-pane.sh claude|codex [MESSAGE]
#
# The hook JSON arrives on stdin. MESSAGE defaults to the text an mcp-tts call
# spoke (tool_input.text). A unique explicit Rexurrect receipt takes priority.
# Otherwise, existing tmux/Zed routing remains available. Codex's shared daemon
# environment does not prove pane ownership; ambiguous matches are never guessed.
max_message_chars=240
max_details_bytes=$((8 * 1024 * 1024))

family=${1:-}
case "$family" in
claude | codex) ;;
*)
	printf 'usage: notify-pane.sh claude|codex [MESSAGE]\n' >&2
	exit 1
	;;
esac
command -v voice-notify >/dev/null 2>&1 || exit 0

input=$(cat)
field() { jq -r --arg name "$1" '.[$name] // empty' <<<"$input"; }
if [[ -n "${2:-}" ]]; then
	details=$2
else
	# The sentinel preserves trailing newlines through command substitution.
	details=$(jq -j '(.tool_input.text // empty), "."' <<<"$input")
	details=${details%.}
fi
message=$(tr -s '[:space:]' ' ' <<<"$details" | sed 's/^ //; s/ $//')
[[ -n "$message" ]] || exit 0
((${#message} <= max_message_chars)) || message="${message:0:max_message_chars-1}…"
# Voice rejects oversized Details without posting. Keep the short notification.
details_bytes=$(printf '%s' "$details" | wc -c)
((details_bytes <= max_details_bytes)) || details=$message
cwd=$(field cwd)
conversation=$(field session_id)
session=$(printf '%s' "$conversation" | tr -cd 'A-Za-z0-9_-')
transcript=$(field transcript_path)

# The config directory names the account: ~/.claude-ddb/projects/…, ~/.codex-team/sessions/….
if [[ "$family" == claude ]]; then
	config=${transcript%%/projects/*}
	config=${config:-${CLAUDE_CONFIG_DIR:-}}
else
	config=${transcript%%/sessions/*}
	config=${config:-${CODEX_HOME:-}}
fi
case "$family:$(basename "${config:-none}")" in
claude:.claude-team) label='Claude Team' ;;
claude:.claude-ddb) label='Claude DDB' ;;
claude:*) label='Claude' ;;
codex:.codex-team) label='Codex Team' ;;
codex:.codex-api) label='Codex API' ;;
codex:*) label='Codex' ;;
esac
project=$(basename "${cwd:-unknown}")

# Rexurrect's configured endpoint is explicit and local. Never select a server,
# session, block, or client from the shared daemon's inherited Rex context.
without_rex_context=(env -u REX_CLIENT -u REX_SESSION -u REX_BLOCK -u REX_SERVER)
rex_session='' rex_block='' rex_where='' rex_issue=''
rex_server=${REXURRECT_SERVER:-"unix://$HOME/Library/Application Support/rex/server.sock"}
rex_state=${REXURRECT_STATE_DIR:-"$HOME/Library/Application Support/rexurrect"}
rex_call() {
	"${without_rex_context[@]}" rex -S "$rex_server" --autostart=false --timeout 1s "$@"
}
resolve_rex() {
	local uuid='[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}'
	local timer matches count target inspection
	[[ $conversation =~ ^${uuid}$ ]] || return 0
	case "$rex_server" in unix:///*) ;; *) return 0 ;; esac
	command -v rex >/dev/null 2>&1 && command -v rexurrect >/dev/null 2>&1 || return 0
	timer=$(command -v timeout || command -v gtimeout || true)
	[[ -n $timer ]] || return 0
	# The receipt-list command has a 30-second lock wait. Bound the whole call
	# within the existing ten-second notification hook deadline.
	if ! matches=$("${without_rex_context[@]}" "$timer" -k 1s 2s rexurrect receipt list \
		--server "$rex_server" --state-dir "$rex_state" --call-timeout 1s --json 2>/dev/null |
		jq -ce --arg host "$family" --arg conversation "$conversation" '
			if type != "array" then error("invalid receipt list") else
			[.[] | select(.host == $host and
				(.conversation | strings | ascii_downcase) == ($conversation | ascii_downcase))] end'); then
		return 0
	fi
	count=$(jq -r length <<<"$matches")
	((count > 0)) || return 0
	if ((count != 1)); then
		rex_issue="ambiguous Rex registration ($count receipts)"
		return 0
	fi
	if ! target=$(jq -er --arg uuid "$uuid" '.[0]
		| select(.command | strings | length > 0)
		| select(.session_id | strings | test("^session:" + $uuid + "$"))
		| select(.block_id | strings | test("^block:" + $uuid + "$"))
		| [.session_id, .block_id] | map(ascii_downcase) | @tsv' <<<"$matches"); then
		rex_issue='invalid Rex registration'
		return 0
	fi
	IFS=$'\t' read -r rex_session rex_block <<<"$target"
	if ! inspection=$(rex_call block inspect "$rex_block" -s "$rex_session" --json 2>/dev/null) ||
		! jq -e --arg session "$rex_session" --arg block "$rex_block" \
			'.session_id == $session and .block.block_id == $block' <<<"$inspection" >/dev/null 2>&1; then
		rex_session='' rex_block=''
		rex_issue='stale Rex registration'
		return 0
	fi
	rex_where=$(rex_call session inspect "$rex_session" --json 2>/dev/null |
		jq -er --arg session "$rex_session" 'select(.session_id == $session) | .label | strings | select(length > 0)') || rex_where=$rex_session
}
resolve_rex

tmux_running() { command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; }
pane=''
candidates=()
if [[ -n "$rex_session" || -n "$rex_issue" ]]; then
	: # A Rex receipt must not be replaced by a same-directory tmux guess.
elif [[ "$family" == claude ]]; then
	# Claude runs hooks inside its own process, so TMUX_PANE is its pane, and an
	# absent TMUX_PANE means it is not in tmux (for example Zed's agent panel).
	if [[ -n "${TMUX_PANE:-}" ]] && tmux_running &&
		tmux display-message -p -t "$TMUX_PANE" '' >/dev/null 2>&1; then
		pane=$TMUX_PANE
	fi
elif [[ -n "$cwd" ]] && tmux_running; then
	# Codex's daemon environment names no pane, or the one it first started from.
	processes=$(ps -axww -o pid=,ppid=,comm=) || processes=''
	runs_codex() {
		awk -v root="$1" '
			{ parent[$1] = $2; name = $3; sub(/.*\//, "", name); command[$1] = name }
			END {
				for (pid in parent) {
					if (command[pid] != "codex") continue
					for (p = pid; p > 1 && (p in parent); p = parent[p]) if (p == root) exit 0
				}
				exit 1
			}' <<<"$processes"
	}
	while IFS=$'\t' read -r id pid path; do
		if [[ "$path" == "$cwd" ]] && runs_codex "$pid"; then
			candidates+=("$id")
		fi
	done < <(tmux list-panes -a -F $'#{pane_id}\t#{pane_pid}\t#{pane_current_path}')
	[[ ${#candidates[@]} -ne 1 ]] || pane=${candidates[0]}
fi

# Voice owns click handling. Give it only an exact pane and server; otherwise
# suppress the CLI's TMUX_PANE default, which may belong to a different session.
click=(--no-pane --no-rex)
if [[ -n "$rex_session" ]]; then
	subtitle="Rex $rex_where ($rex_block)"
	group="agent-rex-${rex_block#block:}"
	click=(--no-pane --rex-session "$rex_session" --rex-block "$rex_block" --rex-server "$rex_server")
elif [[ -n "$rex_issue" ]]; then
	subtitle=$rex_issue
	group="agent-session-${session:-unknown}"
elif [[ -n "$pane" ]]; then
	# A pane can close between listing and lookup; still name it by id.
	where=$(tmux display-message -p -t "$pane" '#{session_name}:#{window_index}.#{pane_index}' \
		2>/dev/null) || where=''
	subtitle="tmux ${where:-pane} ($pane)"
	group="agent-pane-$pane"
	socket=$(tmux display-message -p '#{socket_path}' 2>/dev/null) || socket=''
	[[ -z "$socket" ]] || click=(--pane "$pane" --tmux-socket "$socket" --no-rex)
elif ((${#candidates[@]} > 1)); then
	listed=$(printf '%s, ' "${candidates[@]}")
	subtitle="one of ${#candidates[@]} $label panes in $project: ${listed%, }"
	group="agent-session-${session:-unknown}"
else
	subtitle='not in a tmux pane'
	group="agent-session-${session:-unknown}"
fi

notification=(--title "$label · $project" --subtitle "$subtitle" --message "$message"
	--details-stdin --group "$group" "${click[@]}")
if [[ -z "$rex_session" && "$cwd" == /* && -d "$cwd" ]]; then
	if printf '%s' "$details" | "${without_rex_context[@]}" voice-notify "${notification[@]}" --zed-project "$cwd" >/dev/null 2>&1; then
		exit 0
	else
		notify_status=$?
	fi
	# Voice validates local volumes and symlinks. Keep the original notification
	# when that optional target is rejected, without retrying delivery failures.
	((notify_status == 64)) || exit 0
fi
printf '%s' "$details" | "${without_rex_context[@]}" voice-notify "${notification[@]}" >/dev/null 2>&1 || exit 0
