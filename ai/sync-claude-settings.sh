#!/bin/sh
# Merge the repository's Claude settings into each installed profile.
# Repository keys win. permissions, sandbox and autoMode are replaced whole, so a
# profile cannot keep an extra allow rule or writable path. Other keys that only a
# profile has (model, per-model effort) survive. Hooks merge per event:
# the repository's groups come first, then the profile's machine-local handlers.
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
destination_root=${1:-$HOME}
source_file="$script_dir/claude/settings.json"
# Paths removed from the repository copy; a merge alone would leave them behind.
retired_paths='[["alwaysThinkingEnabled"], ["includeCoAuthoredBy"],
	["skipDangerousModePermissionPrompt"]]'
# Installed handlers the repository owns and so replaces or removes: anything in
# the shared hooks directory (retired scripts such as tts-notify.py included)
# and inline commands the repository has since dropped.
managed_commands='/\.agents/hooks/|Use feature branches, not direct push to main'
# shellcheck disable=SC2016 # jq program, not shell: $names are jq variables.
merge_program='
	def managed($repo_handlers):
		. as $handler
		| (($handler.command // "") | test($managed_commands))
			or any($repo_handlers[]; . == $handler or
				(.command != null and .command == $handler.command));
	def local_groups($repo_groups):
		[$repo_groups[].hooks[]?] as $repo_handlers
		| map(.hooks = [(.hooks // [])[] | select(managed($repo_handlers) | not)])
		| map(select(.hooks | length > 0));
	.[0] as $installed | .[1] as $repo
	| ($installed | delpaths($retired)) * $repo
	| reduce ("permissions", "sandbox", "autoMode") as $owned (.;
		if $repo | has($owned) then .[$owned] = $repo[$owned] else del(.[$owned]) end)
	| (($repo.hooks // {}) | keys_unsorted) as $repo_events
	| .hooks = (
		$repo_events + ((($installed.hooks // {}) | keys_unsorted) - $repo_events)
		| map(. as $event | {
			key: $event,
			value: (($repo.hooks[$event] // []) +
				(($installed.hooks[$event] // []) | local_groups($repo.hooks[$event] // [])))
		})
		| map(select(.value | length > 0))
		| from_entries)
'
temporary=''
trap '[ -z "$temporary" ] || rm -f "$temporary"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

jq empty "$source_file"
for profile in claude claude-team claude-ddb; do
	directory="$destination_root/.$profile"
	[ -d "$directory" ] || continue
	installed="$directory/settings.json"
	temporary=$(mktemp "$directory/.settings.XXXXXX")
	if [ -f "$installed" ]; then
		if ! jq -s --argjson retired "$retired_paths" \
			--arg managed_commands "$managed_commands" "$merge_program" \
			"$installed" "$source_file" >"$temporary"; then
			printf 'Cannot merge %s: fix or remove the invalid JSON, then rerun.\n' "$installed" >&2
			exit 1
		fi
		if cmp -s "$temporary" "$installed"; then
			rm -f "$temporary"
			temporary=''
			continue
		fi
		cp -p "$installed" "$installed.bak"
	else
		jq . "$source_file" >"$temporary"
	fi
	chmod 600 "$temporary"
	mv -f "$temporary" "$installed"
	temporary=''
	printf 'Updated %s\n' "$installed"
done
