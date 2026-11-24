#!/bin/sh
# Install the Antigravity CLI's global hooks and merge the tracked settings into
# the ones agy keeps, under HOME or under $1. Does nothing until ~/.gemini exists.
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
home=${1:-$HOME}
[ -d "$home/.gemini" ] || exit 0

# The repository owns the global hooks file.
mkdir -p "$home/.gemini/config" "$home/.gemini/antigravity-cli"
cp "$script_dir/antigravity/hooks.json" "$home/.gemini/config/hooks.json"

# agy saves trusted folders and "always allow" answers in the same file, so the
# tracked keys are merged in and the rules from both sides are kept. agy matches
# file rules against absolute paths, so ${HOME} in a tracked rule is rendered.
settings="$home/.gemini/antigravity-cli/settings.json"
[ -s "$settings" ] || printf '{}\n' >"$settings"
# shellcheck disable=SC2016 # jq variables and the literal ${HOME} placeholder.
merged=$(jq -s --arg home "$home" '.[0] as $installed
	| (.[1] | walk(if type == "string" then gsub("\\$\\{HOME\\}"; $home) else . end)) as $repo
	| reduce ("allow", "ask", "deny") as $list ($installed * $repo;
		.permissions[$list] = (($installed.permissions[$list] // []) + $repo.permissions[$list] | unique))' \
	"$settings" "$script_dir/antigravity/settings.json")
temporary=$(mktemp "$settings.XXXXXX")
printf '%s\n' "$merged" >"$temporary"
chmod 600 "$temporary"
mv -f "$temporary" "$settings"
