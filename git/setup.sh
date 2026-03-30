#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Git")"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Core ─────────────────────────────────────────────────────────────────────
git config --global core.editor "code -w -n"
git config --global core.pager delta
git config --global core.excludesFile "$HOME/.gitignore_global"

# ── User ─────────────────────────────────────────────────────────────────────
git config --global user.name "blacktop"
git config --global user.email "blacktop@users.noreply.github.com"

# ── Push / Pull / Rebase ────────────────────────────────────────────────────
git config --global push.autoSetupRemote true
git config --global push.default current
git config --global pull.rebase true
git config --global rebase.autoStash true
git config --global init.defaultBranch main

# ── Aliases ──────────────────────────────────────────────────────────────────
git config --global alias.undo "reset --soft HEAD^"

# ── Diff ─────────────────────────────────────────────────────────────────────
git config --global diff.ignoreSubmodules dirty

# ── Delta (pager) ────────────────────────────────────────────────────────────
git config --global delta.line-numbers true
git config --global delta.decorations true
git config --global delta.navigate true
git config --global delta.light false
git config --global delta.side-by-side true
git config --global delta.colorMoved default

# ── Git LFS ──────────────────────────────────────────────────────────────────
git config --global filter.lfs.clean "git-lfs clean -- %f"
git config --global filter.lfs.smudge "git-lfs smudge -- %f"
git config --global filter.lfs.process "git-lfs filter-process"
git config --global filter.lfs.required true

# ── GitHub credential helper (gh CLI) ────────────────────────────────────────
git config --global credential.https://github.com.helper ""
git config --global credential.https://github.com.helper "!/opt/homebrew/bin/gh auth git-credential"
git config --global credential.https://gist.github.com.helper ""
git config --global credential.https://gist.github.com.helper "!/opt/homebrew/bin/gh auth git-credential"

# ── Global gitignore ────────────────────────────────────────────────────────
ln -sf "$SCRIPT_DIR/gitignore_global" "$HOME/.gitignore_global"

# ── gh-dash ──────────────────────────────────────────────────────────────────
# echo "$(gum style --bold --foreground "#BE05D0" "  -") Install gh-dash..."
# gh extension install dlvhdr/gh-dash
# mkdir -p "$HOME/.config/gh-dash"
# cp -r "$SCRIPT_DIR/gh-dash/"* "$HOME/.config/gh-dash/"
