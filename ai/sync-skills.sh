#!/bin/sh
# Sync AI skills to ~/.agents/skills (standardized location for all AI agents)
set -o errexit -o nounset

SCRIPT_DIR="$(dirname "$0")"
AGENTS_SKILLS="$HOME/.agents/skills"

# Create the standardized skills directory
mkdir -p "$AGENTS_SKILLS"

# Clean up stale symlinks from agents that now scan ~/.agents/skills natively
for agent_dir in "$HOME/.gemini" "$HOME/.codex"; do
  skills_path="$agent_dir/skills"
  if [ -L "$skills_path" ]; then
    rm "$skills_path"
  fi
done

# Claude Code is hardcoded to ~/.claude/skills/ (not configurable)
# Symlink it to the unified location so skills aren't duplicated on disk
claude_skills="$HOME/.claude/skills"
if [ ! -L "$claude_skills" ]; then
  # Back up real directory if one exists (don't destroy user's skills)
  if [ -d "$claude_skills" ]; then
    cp -a "$claude_skills/." "$AGENTS_SKILLS/" 2>/dev/null || true
    rm -rf "$claude_skills"
  fi
  ln -s "$AGENTS_SKILLS" "$claude_skills"
fi

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
  skill_name="$(basename "$skill_dir")"
  rsync -a --exclude='.DS_Store' "$skill_dir" "$AGENTS_SKILLS/"
done
