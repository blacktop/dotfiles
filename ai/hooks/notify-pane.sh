#!/bin/bash
set -euo pipefail

# Claude and Codex hook: post a macOS notification naming the tmux pane an agent
# runs in, so a spoken alert heard from another room can be traced to its pane.
#
#   notify-pane.sh claude|codex [MESSAGE]
#
# The hook JSON arrives on stdin. MESSAGE defaults to the text an mcp-tts call
# spoke (tool_input.text). Clicking opens the project in Zed after selecting the
# pane's window and pane in a client already showing its session. Voice falls
# back to the terminal app if Zed fails; it never switches, attaches or detaches
# a tmux client. Codex runs hooks in a shared
# daemon whose environment names no pane,
# so a pane is chosen by matching the session's working directory against panes
# running that agent; several matches are listed instead of guessed.
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
session=$(field session_id | tr -cd 'A-Za-z0-9_-')
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

tmux_running() { command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; }
pane=''
candidates=()
if [[ "$family" == claude ]]; then
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
click=(--no-pane)
if [[ -n "$pane" ]]; then
	# A pane can close between listing and lookup; still name it by id.
	where=$(tmux display-message -p -t "$pane" '#{session_name}:#{window_index}.#{pane_index}' \
		2>/dev/null) || where=''
	subtitle="tmux ${where:-pane} ($pane)"
	group="agent-pane-$pane"
	socket=$(tmux display-message -p '#{socket_path}' 2>/dev/null) || socket=''
	[[ -z "$socket" ]] || click=(--pane "$pane" --tmux-socket "$socket")
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
if [[ "$cwd" == /* && -d "$cwd" ]]; then
	if printf '%s' "$details" | voice-notify "${notification[@]}" --zed-project "$cwd" >/dev/null 2>&1; then
		exit 0
	else
		notify_status=$?
	fi
	# Voice validates local volumes and symlinks. Keep the original notification
	# when that optional target is rejected, without retrying delivery failures.
	((notify_status == 64)) || exit 0
fi
printf '%s' "$details" | voice-notify "${notification[@]}" >/dev/null 2>&1 || exit 0
