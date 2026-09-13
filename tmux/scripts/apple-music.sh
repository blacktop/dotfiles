#!/usr/bin/env bash
# Render the current Apple Music track for the tmux status bar.
# Emits a fully-formatted rose-pine section (icon + artist: track + trailing
# divider) when playing or paused, and nothing at all otherwise — so a stopped
# or closed Music app leaves no dangling separator in the bar.
#
# One osascript call returns all fields (status-interval is 1s, so spawning
# three osascript processes per second would be wasteful). `application "Music"
# is running` is queried first and never launches the app.
set -euo pipefail

# Colors match the theme: iris for the music section, muted for the divider.
readonly C_MUSIC='#[fg=#c4a7e7]'
readonly C_DIV='#[fg=#908caa]'
readonly ICON_PLAYING='󰐊'
readonly ICON_PAUSED='󰏤'

info=$(osascript <<'APPLESCRIPT' 2>/dev/null || true
if application "Music" is running then
  tell application "Music"
    set pstate to player state as string
    if pstate is "playing" or pstate is "paused" then
      try
        return pstate & linefeed & (artist of current track as string) & linefeed & (name of current track as string)
      end try
    end if
  end tell
end if
APPLESCRIPT
)

[ -n "$info" ] || exit 0

state=$(printf '%s' "$info" | sed -n '1p')
artist=$(printf '%s' "$info" | sed -n '2p')
track=$(printf '%s' "$info" | sed -n '3p')

[ -n "$track" ] || exit 0

if [ "$state" = "playing" ]; then
  icon=$ICON_PLAYING
else
  icon=$ICON_PAUSED
fi

if [ -n "$artist" ]; then
  printf '%s%s %s: %s%s ·' "$C_MUSIC" "$icon" "$artist" "$track" "$C_DIV"
else
  printf '%s%s %s%s ·' "$C_MUSIC" "$icon" "$track" "$C_DIV"
fi
