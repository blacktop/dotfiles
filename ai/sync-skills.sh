#!/bin/sh
# Sync AI skills to ~/.agents/skills (standardized location for all AI agents)
set -o errexit -o nounset

SCRIPT_DIR="$(dirname "$0")"
AGENTS_SKILLS="$HOME/.agents/skills"

# Create the standardized skills directory
mkdir -p "$AGENTS_SKILLS"

# Create symlinks from legacy agent skill directories to unified location
# (codex already reads from ~/.agents/skills natively)
for agent_dir in "$HOME/.claude" "$HOME/.gemini" "$HOME/.codex"; do
  skills_path="$agent_dir/skills"
  # Remove existing directory or broken symlink
  if [ -d "$skills_path" ] && [ ! -L "$skills_path" ]; then
    rm -rf "$skills_path"
  elif [ -L "$skills_path" ]; then
    rm "$skills_path"
  fi
  # Create symlink to unified location
  mkdir -p "$agent_dir"
  ln -s "$AGENTS_SKILLS" "$skills_path"
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
  skill_name="$(basename "$skill_dir")"
  rsync -a --exclude='.DS_Store' "$skill_dir" "$AGENTS_SKILLS/"
done
