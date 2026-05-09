#!/bin/sh
# Sync AI skills to ~/.agents/skills (standardized location for all AI agents)
set -o errexit -o nounset

SCRIPT_DIR="$(dirname "$0")"
AGENTS_SKILLS="$HOME/.agents/skills"

# Create the standardized skills directory
mkdir -p "$AGENTS_SKILLS"

# Claude Code looks at $CLAUDE_CONFIG_DIR/skills/; codex CLI looks at $CODEX_HOME/skills/.
# Symlink each variant to the unified ~/.agents/skills location so skills live in one place.
for agent_dir in "$HOME/.claude" "$HOME/.claude-team" "$HOME/.codex" "$HOME/.codex-team"; do
	[ -d "$agent_dir" ] || continue
	skills_path="$agent_dir/skills"
	if [ ! -L "$skills_path" ]; then
		if [ -d "$skills_path" ]; then
			cp -a "$skills_path/." "$AGENTS_SKILLS/" 2>/dev/null || true
			rm -rf "$skills_path"
		fi
		ln -s "$AGENTS_SKILLS" "$skills_path"
	fi
done

# Gemini scans ~/.agents/skills natively; remove any stale symlink from older setups.
gemini_skills="$HOME/.gemini/skills"
[ -L "$gemini_skills" ] && rm "$gemini_skills"

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
	rsync -a --exclude='.DS_Store' "$skill_dir" "$AGENTS_SKILLS/"
done
