#!/bin/sh
# Sync AI skills to ~/.agents/skills (standardized location for all AI agents)
set -o errexit -o nounset

SCRIPT_DIR="$(dirname "$0")"
AGENTS_SKILLS="$HOME/.agents/skills"

# Create the standardized skills directory
mkdir -p "$AGENTS_SKILLS"

# Claude Code looks at $CLAUDE_CONFIG_DIR/skills/; codex CLI looks at $CODEX_HOME/skills/.
# Symlink each normal variant to the unified ~/.agents/skills location so skills live in one place.
# ~/.claude-fable is intentionally excluded so its Fable sessions stay vanilla.
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

# Install community skills (installs directly to ~/.agents/skills)
if [ -x "$SCRIPT_DIR/skills/install-community.sh" ]; then
	"$SCRIPT_DIR/skills/install-community.sh"
fi

# Copy personal skills to ~/.agents/skills
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
	[ -d "$skill_dir" ] || continue
	# Skip if it's not a skill directory (no SKILL.md)
	[ -f "$skill_dir/SKILL.md" ] || continue
	# Remove trailing slash
	skill_dir="${skill_dir%/}"
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
