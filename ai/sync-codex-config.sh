#!/bin/sh
# Rebuild each installed Codex config from the repository template plus the state
# Codex and its desktop app write. Everything else in an installed file, such as a
# legacy sandbox_mode or a notify command, is replaced by the template.
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
destination_root=${1:-$HOME}
template="$script_dir/codex/config.toml"
# Top-level keys the CLI writes when you pick a model.
kept_keys='^(model|review_model|model_reasoning_effort|service_tier)[[:space:]]*='
# Tables Codex writes; a header the template also defines is never kept.
kept_tables='^\[+(projects\.|plugins\.|marketplaces\.|mcp_servers\.|notice[].]|desktop[].]|hooks\.state\.")'
# MCP servers the template renamed or now forbids; dropped with their subtables.
retired_servers='^\[+mcp_servers\."?(computer-use|ida-pro)"?[].]'
work=''
trap '[ -z "$work" ] || rm -rf "$work"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

for profile in codex codex-team; do
	directory="$destination_root/.$profile"
	[ -d "$directory" ] || continue
	installed="$directory/config.toml"
	work=$(mktemp -d "$directory/.config.XXXXXX")
	sed "s|\${HOME}|$HOME|g" "$template" >"$work/template"
	[ -f "$installed" ] || : >"$work/installed"
	[ ! -f "$installed" ] || cp "$installed" "$work/installed"
	{
		awk '/^\[/ { exit } { print }' "$work/template"
		awk '/^\[/ { exit } { print }' "$work/installed" | grep -E "$kept_keys" || true
		printf '\n'
		awk 'found || /^\[/ { found = 1; print }' "$work/template"
		printf '\n# ── Kept from the installed file ─────────────────────────────────────────────\n'
		KEPT_TABLES="$kept_tables" RETIRED_SERVERS="$retired_servers" awk '
			# First file: remember every template header and managed MCP server.
			NR == FNR {
				if ($0 ~ /^\[/) {
					header[$0] = 1
					if (match($0, /^\[+mcp_servers\.[^].]+/)) {
						server[substr($0, RSTART, RLENGTH)] = 1
					}
				}
				next
			}
			/^\[/ {
				keep = ($0 ~ ENVIRON["KEPT_TABLES"]) && !($0 in header)
				keep = keep && !($0 ~ ENVIRON["RETIRED_SERVERS"])
				if (keep && match($0, /^\[+mcp_servers\.[^].]+/)) {
					keep = !(substr($0, RSTART, RLENGTH) in server)
				}
			}
			keep { print }
		' "$work/template" "$work/installed"
	} >"$work/config.toml"
	mkdir "$work/home"
	cp "$work/config.toml" "$work/home/config.toml"
	if command -v codex >/dev/null 2>&1 &&
		! CODEX_HOME="$work/home" codex features list >/dev/null 2>"$work/error"; then
		printf 'Codex rejected the rebuilt %s; it was left unchanged:\n' "$installed" >&2
		cat "$work/error" >&2
		exit 1
	fi
	if [ -f "$installed" ] && cmp -s "$work/config.toml" "$installed"; then
		rm -rf "$work"
		work=''
		continue
	fi
	[ ! -f "$installed" ] || cp -p "$installed" "$installed.bak"
	chmod 600 "$work/config.toml"
	mv -f "$work/config.toml" "$installed"
	rm -rf "$work"
	work=''
	printf 'Updated %s\n' "$installed"
done
