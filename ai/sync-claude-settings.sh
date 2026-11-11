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
# Resolve the native per-user temp directory on this host, not from shell state.
macos_tmp=''
if [ "$(uname -s)" = Darwin ]; then
	macos_tmp=$(getconf DARWIN_USER_TEMP_DIR)
	case "$macos_tmp" in
	/*) ;;
	*)
		printf 'Cannot resolve the native macOS user temporary directory.\n' >&2
		exit 1
		;;
	esac
	macos_tmp=$(CDPATH='' cd -- "$macos_tmp" && pwd -P)
	[ "$macos_tmp" != / ] || {
		printf 'Refusing a root-directory temp allowance.\n' >&2
		exit 1
	}
fi
# A host that opted in through ai/setup.sh runs agents without a sandbox or
# permission prompts. Deny rules and hooks still apply in bypass mode, so the
# guards for irreversible or outward-facing actions stay: rm, sudo, disk tools,
# piping downloads into a shell, force-push, hard reset, publishing, and reading
# secret stores. Plain git push, force-add, shell-config edits and all of ~/.ssh
# (so agents can use ssh and read its config) are allowed.
yolo=0
[ ! -e "$destination_root/.agents/yolo" ] || yolo=1
# shellcheck disable=SC2016 # jq variables, not shell variables.
host_settings='
	def yolo:
		if $yolo == "1" then
			.permissions = {
				defaultMode: "bypassPermissions",
				deny: (
					[(.permissions.deny // [])[]
						| select(test("git push|git add|^Edit\\(|\\.ssh") | not)]
					+ [(.permissions.ask // [])[] | select(test("publish|release delete"))]
					+ ["Bash(git push *--force*)", "Bash(git push -f*)", "Bash(git push * -f*)",
						"Bash(*Library/Keychains*)", "Bash(*/.gnupg*)", "Bash(*/auth.json*)",
						"Bash(*.git-credentials*)", "Bash(*/.netrc*)", "Bash(security find-*)"]
				)
			}
			| .sandbox = {enabled: false}
			| del(.autoMode)
			| .hooks.PreToolUse |= (map(.hooks |= map(select(.command // ""
				| test("Use trash instead of rm|locals\\.fish|do not dump env"))))
				| map(select(.hooks | length > 0)))
		else . end;
	def with_host_paths:
		if $macos_tmp != "" and has("sandbox") then
			.sandbox.filesystem.allowWrite |=
				((. // []) | if index($macos_tmp) == null then . + [$macos_tmp] else . end)
		else . end
		| if .sandbox.network.allowUnixSockets? then
			.sandbox.network.allowUnixSockets |=
				map(if startswith("~/") then $home + .[1:] else . end)
		else . end;
'
# Paths removed from the repository copy; a merge alone would leave them behind.
retired_paths='[["alwaysThinkingEnabled"], ["includeCoAuthoredBy"],
	["skipDangerousModePermissionPrompt"]]'
# Installed handlers the repository owns and so replaces or removes: anything in
# the shared hooks directory (retired scripts such as tts-notify.py included),
# inline commands the repository has since dropped, and the session hooks of the
# tmux-assistant-resurrect plugin, which tmux/setup.sh retires.
managed_commands='/\.agents/hooks/|Use feature branches, not direct push to main'
managed_commands="$managed_commands"'|/\.tmux/plugins/tmux-assistant-resurrect/'
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
	.[0] as $installed | .[1] as $source | ($source | with_host_paths | yolo) as $repo
	| ($installed | delpaths($retired)) * $repo
	| reduce ("permissions", "sandbox", "autoMode") as $owned (.;
		if $repo | has($owned) then .[$owned] = $repo[$owned] else del(.[$owned]) end)
	| (($repo.hooks // {}) | keys_unsorted) as $repo_events
	| .hooks = (
		$repo_events + ((($installed.hooks // {}) | keys_unsorted) - $repo_events)
		| map(. as $event | {
			key: $event,
			value: (($repo.hooks[$event] // []) +
				(($installed.hooks[$event] // []) | local_groups($source.hooks[$event] // [])))
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
			--arg managed_commands "$managed_commands" --arg macos_tmp "$macos_tmp" --arg home "$HOME" \
			--arg yolo "$yolo" "$host_settings $merge_program" \
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
		jq --arg macos_tmp "$macos_tmp" --arg home "$HOME" --arg yolo "$yolo" \
			"$host_settings with_host_paths | yolo" "$source_file" >"$temporary"
	fi
	chmod 600 "$temporary"
	mv -f "$temporary" "$installed"
	temporary=''
	printf 'Updated %s\n' "$installed"
done
