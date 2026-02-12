#!/bin/sh
# Sync AI skills to ~/.agents/skills (standardized location for all AI agents)
set -o errexit -o nounset

SCRIPT_DIR="$(dirname "$0")"
AGENTS_SKILLS="$HOME/.agents/skills"

# Create the standardized skills directory
mkdir -p "$AGENTS_SKILLS"

# Clean up stale symlinks for agents that now read ~/.agents/skills natively
for agent_dir in "$HOME/.gemini" "$HOME/.codex"; do
  skills_path="$agent_dir/skills"
  if [ -L "$skills_path" ]; then
    rm "$skills_path"
  fi
done

# Claude Code is the only agent that doesn't scan ~/.agents/skills natively,
# so it still needs a symlink from ~/.claude/skills -> ~/.agents/skills.
claude_skills="$HOME/.claude/skills"
if [ -d "$claude_skills" ] && [ ! -L "$claude_skills" ]; then
  rm -rf "$claude_skills"
elif [ -L "$claude_skills" ]; then
  rm "$claude_skills"
fi
mkdir -p "$HOME/.claude"
ln -s "$AGENTS_SKILLS" "$claude_skills"

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
