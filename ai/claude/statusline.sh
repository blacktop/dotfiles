#!/bin/bash
# Claude Code statusline — minimal, no background fills
set -euo pipefail

input=$(cat)

if ! echo "$input" | jq -e . >/dev/null 2>&1; then
  exit 0
fi

# ── colors (foreground only, rendered dim by Claude Code) ─────────────────────
RESET=$'\033[0m'
DIM=$'\033[2m'
C_MUTED=$'\033[38;5;242m'   # gray — separators
C_BASE=$'\033[38;5;250m'    # light gray — default text
C_BLUE=$'\033[38;5;75m'     # blue — model / dir
C_GREEN=$'\033[38;5;71m'    # green — clean git
C_YELLOW=$'\033[38;5;179m'  # yellow — dirty git
C_RED=$'\033[38;5;167m'     # red — high context / INSERT mode
C_CYAN=$'\033[38;5;73m'     # cyan — agent / worktree / NORMAL mode
C_ORANGE=$'\033[38;5;173m'  # orange — context warning

SEP="${C_MUTED}·${RESET}"

# ── extract fields ─────────────────────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
dir_name=$(basename "${cwd:-?}" 2>/dev/null)

model=$(echo "$input" | jq -r '
  if .model | type == "object" then .model.display_name // .model.id // "claude"
  elif .model | type == "string" then .model
  else "claude"
  end
' 2>/dev/null)
[ -z "$model" ] || [ "$model" = "null" ] && model="claude"
# Shorten: "Claude 3.5 Sonnet" -> "sonnet-3.5", raw IDs drop date suffix
model=$(echo "$model" | sed '
  s/Claude //I
  s/ /\-/g
  s/[Ss]onnet/sonnet/
  s/[Hh]aiku/haiku/
  s/[Oo]pus/opus/
' | tr '[:upper:]' '[:lower:]' | sed 's/-[0-9]\{8\}$//')

vim_mode=$(echo "$input" | jq -r '.vim.mode // empty' 2>/dev/null)
agent_name=$(echo "$input" | jq -r '.agent.name // empty' 2>/dev/null)
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // .worktree.name // empty' 2>/dev/null)
session_name=$(echo "$input" | jq -r '.session_name // empty' 2>/dev/null)

# ── git ────────────────────────────────────────────────────────────────────────
git_part=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

  porcelain=$(git -C "$cwd" status --porcelain 2>/dev/null)
  staged=$(echo "$porcelain" | grep -c '^[MADRC]' || true)
  modified=$(echo "$porcelain" | grep -c '^.[MD]' || true)
  ahead=$(git -C "$cwd" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
  behind=$(git -C "$cwd" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

  flags=""
  [ "${ahead:-0}" -gt 0 ] && flags+="⇡${ahead}"
  [ "${behind:-0}" -gt 0 ] && flags+="⇣${behind}"
  [ "${staged:-0}" -gt 0 ] && flags+="+${staged}"
  [ "${modified:-0}" -gt 0 ] && flags+="!${modified}"

  git_color=$C_GREEN
  [ -n "$flags" ] && git_color=$C_YELLOW
  git_part="${git_color}${branch}${flags:+ ${flags}}${RESET}"
fi

# ── context ────────────────────────────────────────────────────────────────────
ctx_part=""
pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
if [ -n "$pct" ] && [ "$pct" != "null" ]; then
  pct_int=$(printf '%.0f' "$pct" 2>/dev/null || echo "$pct")
  if [ "${pct_int:-0}" -gt 85 ]; then
    ctx_color=$C_RED
  elif [ "${pct_int:-0}" -gt 65 ]; then
    ctx_color=$C_ORANGE
  else
    ctx_color=$C_MUTED
  fi
  ctx_part="${ctx_color}ctx:${pct_int}%${RESET}"
fi

# ── rate limits (claude.ai subscribers) ───────────────────────────────────────
rate_part=""
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  rate_str=""
  [ -n "$five_pct" ] && rate_str+="5h:$(printf '%.0f' "$five_pct")%"
  [ -n "$week_pct" ] && rate_str+="${rate_str:+ }7d:$(printf '%.0f' "$week_pct")%"
  rate_part="${C_MUTED}${rate_str}${RESET}"
fi

# ── assemble ───────────────────────────────────────────────────────────────────
parts=()

# vim mode (only when active)
if [ -n "$vim_mode" ]; then
  case "$vim_mode" in
    INSERT) parts+=("${C_RED}I${RESET}") ;;
    NORMAL) parts+=("${C_CYAN}N${RESET}") ;;
    *)      parts+=("${C_MUTED}${vim_mode}${RESET}") ;;
  esac
fi

# model
parts+=("${C_BLUE}${model}${RESET}")

# dir
parts+=("${C_BASE}${dir_name}${RESET}")

# git
[ -n "$git_part" ] && parts+=("$git_part")

# worktree (when different from current branch)
[ -n "$worktree_branch" ] && parts+=("${C_CYAN}wt:${worktree_branch}${RESET}")

# agent name
[ -n "$agent_name" ] && parts+=("${C_CYAN}@${agent_name}${RESET}")

# session name
[ -n "$session_name" ] && parts+=("${DIM}${C_MUTED}${session_name}${RESET}")

# context usage
[ -n "$ctx_part" ] && parts+=("$ctx_part")

# rate limits
[ -n "$rate_part" ] && parts+=("$rate_part")

# join with separator
out=""
for part in "${parts[@]}"; do
  [ -n "$out" ] && out+=" ${SEP} "
  out+="$part"
done

printf '%s' "$out"
