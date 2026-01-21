#!/bin/sh
# Sync AI skills to CLI agent config directories
set -o errexit -o nounset

SKILLS_SRC="$(dirname "$0")/skills"

[ ! -d "$SKILLS_SRC" ] && exit 0

for target in "$HOME/.claude/skills" "$HOME/.codex/skills"; do
  mkdir -p "$target"
  rsync -a --delete --exclude='.DS_Store' "$SKILLS_SRC/" "$target/"
done
