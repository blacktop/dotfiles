#!/bin/sh
# Sync AI skills to agent config directories
set -o errexit -o nounset

SCRIPT_DIR="$(dirname "$0")"

# Clean up any old symlinks that might exist at skills paths
for target in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.gemini/skills"; do
  if [ -L "$target" ]; then
    rm "$target"
  fi
done

# Install community skills (installs directly to each agent's skills folder)
if [ -x "$SCRIPT_DIR/skills/install-community.sh" ]; then
  "$SCRIPT_DIR/skills/install-community.sh"
fi

# Copy personal skills to each agent's skills folder
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
  [ -d "$skill_dir" ] || continue
  # Skip if it's not a skill directory (no SKILL.md)
  [ -f "$skill_dir/SKILL.md" ] || continue
  # Remove trailing slash
  skill_dir="${skill_dir%/}"
  skill_name="$(basename "$skill_dir")"
  # Copy to each agent's skills folder
  for target in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.gemini/skills"; do
    mkdir -p "$target"
    rsync -a --exclude='.DS_Store' "$skill_dir" "$target/"
  done
done
