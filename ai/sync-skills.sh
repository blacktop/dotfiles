#!/bin/sh
# Sync AI skills to ~/.agents/skills (standardized location for all AI agents)
set -o errexit -o nounset

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
AGENTS_SKILLS="$HOME/.agents/skills"

# Create the standardized skills directory
mkdir -p "$AGENTS_SKILLS"

# Claude Code looks at $CLAUDE_CONFIG_DIR/skills/; codex CLI looks at $CODEX_HOME/skills/.
# Symlink each normal variant to the unified ~/.agents/skills location so skills live in one place.
for agent_dir in "$HOME/.claude" "$HOME/.claude-team" "$HOME/.claude-ddb" "$HOME/.codex" "$HOME/.codex-team"; do
	[ -d "$agent_dir" ] || continue
	skills_path="$agent_dir/skills"
	if [ ! -L "$skills_path" ]; then
		if [ -d "$skills_path" ]; then
			cp -a "$skills_path/." "$AGENTS_SKILLS/"
			rm -rf "$skills_path"
		fi
		ln -s "$AGENTS_SKILLS" "$skills_path"
	fi
done

# Install community skills (installs directly to ~/.agents/skills). Fetching them
# is the slow part of setup, so a terminal run may skip it once they have been
# installed; a first install, or a run with no terminal to ask, always fetches.
update_community=yes
if [ -t 0 ] && [ -f "$HOME/.agents/.skill-lock.json" ] &&
	! gum confirm --default=false "Update community skills? (slow; No just re-syncs local skills)"; then
	update_community=no
fi
if [ "$update_community" = yes ]; then
	"$SCRIPT_DIR/skills/install-community.sh"
else
	echo "$(gum style --bold --foreground "#FF9400" "  •") Skipped community skills"
fi

# Copy personal skills to ~/.agents/skills
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
	[ -d "$skill_dir" ] || continue
	# Skip if it's not a skill directory (no SKILL.md)
	[ -f "$skill_dir/SKILL.md" ] || continue
	# Remove trailing slash
	skill_dir="${skill_dir%/}"
	if [ -L "$AGENTS_SKILLS/$(basename "$skill_dir")" ]; then
		printf 'Refusing to overwrite linked skill: %s\n' "$(basename "$skill_dir")" >&2
		exit 1
	fi
	# evals/ holds skill-creator benchmark fixtures and __pycache__ holds compiled
	# bytecode — both are dev-only and gitignored, so don't deploy them.
	# --delete prunes files removed from the repo copy. It is scoped to the single
	# skill directory being transferred, so sibling skills (including community
	# ones) in $AGENTS_SKILLS are never touched. Excluded paths are also protected
	# on the receiving side, so a stray evals/ there survives rather than being
	# pruned. Verified identical on openrsync (/usr/bin) and rsync 3.x (Homebrew).
	rsync -a --delete --exclude='.DS_Store' --exclude='evals' --exclude='__pycache__' \
		"$skill_dir" "$AGENTS_SKILLS/"
done

# Private content stays outside this repository. Links follow local Git updates.
"$SCRIPT_DIR/sync-private-skills.sh" \
	"${PRIVATE_SKILLS_DIR:-$SCRIPT_DIR/../../private-skills}" "$AGENTS_SKILLS"
