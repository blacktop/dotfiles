#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
label=com.blacktop.cargo-clean-big-targets
bin_dir=$HOME/.local/bin
agent_dir=$HOME/Library/LaunchAgents
log_dir=$HOME/Library/Logs
installed_script=$bin_dir/cargo-clean-big-targets
installed_plist=$agent_dir/$label.plist

mkdir -p "$bin_dir" "$agent_dir" "$log_dir"
install -m 0755 "$script_dir/cargo-clean-big-targets.sh" "$installed_script"

temporary_plist=$(/usr/bin/mktemp "$agent_dir/$label.plist.XXXXXX")
trap '/bin/rm -f "$temporary_plist"' EXIT HUP INT TERM
/usr/bin/sed "s|__HOME__|$HOME|g" \
    "$script_dir/com.blacktop.cargo-clean-big-targets.plist" >"$temporary_plist"
/usr/bin/plutil -lint "$temporary_plist" >/dev/null
/bin/chmod 0644 "$temporary_plist"
/bin/mv "$temporary_plist" "$installed_plist"
trap - EXIT HUP INT TERM

domain=gui/$(/usr/bin/id -u)
service=$domain/$label

if /bin/launchctl print "$domain" >/dev/null 2>&1; then
    /bin/launchctl bootout "$service" >/dev/null 2>&1 || true
    /bin/launchctl enable "$service"
    /bin/launchctl bootstrap "$domain" "$installed_plist"
    printf 'Installed and scheduled %s\n' "$service"
else
    printf 'Installed %s; it will load at the next GUI login\n' "$installed_plist"
fi

printf 'Dry run: %s --dry-run\n' "$installed_script"
printf 'Run now: launchctl kickstart -k %s\n' "$service"
