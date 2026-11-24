#!/bin/sh
# Lay out the skills directory of each agent profile under HOME, or under $1.
#
# Claude Code reads only $CLAUDE_CONFIG_DIR/skills, so each Claude profile links
# it to the shared ~/.agents/skills.
#
# Codex reads ~/.agents/skills itself and installs its bundled skills in
# $CODEX_HOME/skills/.system. A session reinstalls them whenever the fingerprint
# there is not the one of its own build, and every session watching the
# directory then reloads. Linked to the shared directory, all three homes and
# every build on the host rewrote one .system in turn, so each Codex home keeps
# a real skills directory of its own.
set -eu

home=${1:-$HOME}
shared="$home/.agents/skills"
mkdir -p "$shared"

for profile in .claude .claude-team .claude-ddb; do
	[ -d "$home/$profile" ] || continue
	skills="$home/$profile/skills"
	[ ! -L "$skills" ] || continue
	if [ -d "$skills" ]; then
		cp -a "$skills/." "$shared/"
		rm -rf "$skills"
	fi
	ln -s "$shared" "$skills"
done

for profile in .codex .codex-team .codex-api; do
	[ -d "$home/$profile" ] || continue
	skills="$home/$profile/skills"
	if [ -L "$skills" ]; then
		rm "$skills"
	fi
	mkdir -p "$skills"
done

# Antigravity reads extra skill folders from a discovery manifest, in the CLI
# and the App alike. It does not expand ~, so the path is absolute.
if [ -d "$home/.gemini" ]; then
	mkdir -p "$home/.gemini/config"
	printf '{\n  "entries": [{ "path": "%s" }]\n}\n' "$shared" >"$home/.gemini/config/skills.json"
fi

# The bundled skills the linked Codex homes left in the shared directory. The
# marker shows the directory is the one Codex installs, which nothing reads here
# now. A session started before this layout can still be rewriting it.
if [ -f "$shared/.system/.codex-system-skills.marker" ] && ! rm -rf "$shared/.system"; then
	printf 'Kept %s: a running Codex session is rewriting it. Restart Codex, then rerun.\n' \
		"$shared/.system" >&2
fi
