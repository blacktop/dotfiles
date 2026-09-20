#!/bin/bash
set -euo pipefail

# Claude Notification and StopFailure hook. Every alert is a local desktop
# banner that Claude emits through its own terminal (OSC 777, Ghostty, passes
# through tmux), plus a spoken phrase: voice-say with a delivery style for
# approval and failure, the system voice for input requests. Banner and phrase
# are fixed text chosen from the event type; the prompt, tool input and error
# text in the payload are never read. Any failure exits quietly so the notifier
# cannot disturb a turn.
cooldown_seconds=60
mute_file="$HOME/.agents/notify-mute"

input=$(cat)
key=$(jq -r '"\(.hook_event_name // ""):\(.notification_type // .error // "")"' <<<"$input") || exit 0
session=$(jq -r '.session_id // ""' <<<"$input" | tr -cd 'A-Za-z0-9_-') || exit 0

# An empty style means the system voice.
style=''
case "$key" in
Notification:permission_prompt)
	slot='approval' body='Needs approval' spoken='needs approval'
	style='calm and clear'
	;;
Notification:elicitation_dialog | Notification:elicitation_url_dialog)
	slot='mcp-input' body='An MCP server needs input'
	spoken='has an MCP server waiting for input'
	;;
Notification:agent_needs_input)
	slot='agent-input' body='A background agent needs input'
	spoken='has a background agent waiting for input'
	;;
StopFailure:rate_limit | StopFailure:overloaded | StopFailure:server_error)
	slot='failure' body='Turn stopped: the API is busy'
	spoken='stopped because the API is busy'
	style='calm, a little concerned'
	;;
StopFailure:authentication_failed | StopFailure:oauth_org_not_allowed | \
	StopFailure:billing_error | StopFailure:account_on_hold)
	slot='failure' body='Turn stopped: sign-in or billing problem'
	spoken='stopped on a sign-in or billing problem'
	style='serious and urgent'
	;;
StopFailure:*)
	slot='failure' body='Turn ended with an API error'
	spoken='stopped on an API error'
	style='serious'
	;;
*)
	exit 0
	;;
esac

case "$(basename "${CLAUDE_CONFIG_DIR:-}")" in
.claude-team) title='Claude Team' ;;
.claude-ddb) title='Claude DDB' ;;
*) title='Claude' ;;
esac

# One alert per session and slot within the cooldown.
state_dir="${TMPDIR:-/tmp}/agents-notify-$(id -u)"
mkdir -m 700 "$state_dir" 2>/dev/null || true
[[ -d "$state_dir" && -O "$state_dir" && ! -L "$state_dir" ]] || exit 0
stamp="$state_dir/${session:-unknown}.$slot"
now=$(date +%s)
last=$(cat "$stamp" 2>/dev/null || true)
[[ "$last" =~ ^[0-9]+$ ]] || last=0
((now - last >= cooldown_seconds)) || exit 0
printf '%s\n' "$now" >"$stamp" || exit 0

speak() {
	if [[ -n "$style" ]] && command -v voice-say >/dev/null 2>&1 &&
		voice-say --quiet --wait --tier small --style "$style" "$title $spoken"; then
		return 0
	fi
	command -v say >/dev/null 2>&1 || return 0
	say "$title $spoken"
}
# Detached: synthesis takes seconds and the banner must not wait for it.
if [[ ! -e "$mute_file" ]]; then
	speak </dev/null >/dev/null 2>&1 &
fi

sequence=$(printf '\033]777;notify;%s;%s\007' "$title" "$body")
jq -nc --arg sequence "$sequence" '{terminalSequence: $sequence}'
