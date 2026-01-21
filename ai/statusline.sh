#!/bin/bash
# Claude Code statusline with powerline style and git status
# Uses nerd fonts and ANSI colors for rainbow effect

input=$(cat)

# Validate JSON and extract fields safely
if ! echo "$input" | jq -e . >/dev/null 2>&1; then
  echo "⚠ invalid input"
  exit 0
fi

cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
dir_name=$(basename "$cwd" 2>/dev/null || echo "?")

# Extract model - could be string or object with .id field
model=$(echo "$input" | jq -r '
  if .model | type == "object" then .model.id // .model.name // "claude"
  elif .model | type == "string" then .model
  else "claude"
  end
' 2>/dev/null)
[ -z "$model" ] || [ "$model" = "null" ] && model="claude"
# Clean up model name - remove claude- prefix and date suffix, truncate
model=$(echo "$model" | sed 's/claude-//' | sed 's/-[0-9]*$//' | cut -c1-10)

# ANSI color codes (using $'...' for proper escape handling)
RESET=$'\033[0m'
BG_BLUE=$'\033[44m'
FG_BLUE=$'\033[34m'
BG_GREEN=$'\033[42m'
FG_GREEN=$'\033[32m'
BG_YELLOW=$'\033[43m'
FG_YELLOW=$'\033[33m'
BG_CYAN=$'\033[46m'
FG_CYAN=$'\033[36m'
BG_RED=$'\033[41m'
FG_RED=$'\033[31m'
BG_ORANGE=$'\033[48;5;208m'
FG_ORANGE=$'\033[38;5;208m'
BG_MAGENTA=$'\033[45m'
FG_MAGENTA=$'\033[35m'
FG_BLACK=$'\033[30m'
FG_WHITE=$'\033[97m'
BOLD=$'\033[1m'
BLINK=$'\033[5m'

# Powerline separator (U+E0B0)
SEP=$''

# Nerd font icons (literal characters)
ICON_ROBOT='󱚝'
ICON_FOLDER='󱧨'
ICON_GIT=''

# Dark background for progress bar
BG_DARK=$'\033[48;5;236m'
FG_DARK=$'\033[38;5;236m'

# Git info - check status first to determine model background color
has_git=false
model_bg=$BG_GREEN
model_fg=$FG_GREEN
BG_LTBLUE=$'\033[48;5;75m'
FG_LTBLUE=$'\033[38;5;75m'

if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  has_git=true
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

  # Get status counts
  status=$(git -C "$cwd" status --porcelain 2>/dev/null)
  staged=$(echo "$status" | grep -c '^[MADRC]')
  modified=$(echo "$status" | grep -c '^.[MD]')

  # Ahead/behind
  ahead=$(git -C "$cwd" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
  behind=$(git -C "$cwd" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

  # Build compact git status (starship style)
  git_status=""
  [ "$ahead" -gt 0 ] 2>/dev/null && git_status+="⇡$ahead"
  [ "$behind" -gt 0 ] 2>/dev/null && git_status+="⇣$behind"
  [ "$staged" -gt 0 ] && git_status+="+$staged"
  [ "$modified" -gt 0 ] && git_status+="!$modified"

  if [ -n "$git_status" ]; then
    model_bg=$BG_YELLOW
    model_fg=$FG_YELLOW
    git_content=" ${ICON_GIT} $branch $git_status "
  else
    git_content=" ${ICON_GIT} $branch "
  fi
fi

# Context progress bar
pct=$(echo "$input" | jq '.context_window.used_percentage // empty' 2>/dev/null)
has_context=false
if [ -n "$pct" ] && [ "$pct" != "null" ] && [ "$pct" -ge 0 ] 2>/dev/null; then
  has_context=true
  bar_width=10
  filled=$((pct * bar_width / 100))
  [ "$filled" -gt "$bar_width" ] && filled=$bar_width
  empty=$((bar_width - filled))

  if [ "$pct" -gt 95 ]; then
    fill_color=$'\033[38;5;196m'
    bar_blink=$BLINK
  elif [ "$pct" -gt 85 ]; then
    fill_color=$'\033[38;5;208m'
    bar_blink=""
  elif [ "$pct" -gt 70 ]; then
    fill_color=$'\033[38;5;220m'
    bar_blink=""
  else
    fill_color=$'\033[38;5;29m'
    bar_blink=""
  fi
  empty_color=$'\033[38;5;240m'

  filled_bar=""
  empty_bar=""
  for ((i = 0; i < filled; i++)); do filled_bar+="█"; done
  for ((i = 0; i < empty; i++)); do empty_bar+="░"; done
  context_content="${bar_blink}${fill_color}${filled_bar}${RESET}${BG_DARK}${empty_color}${empty_bar}${FG_WHITE} ${pct}%"
fi

# Build output with proper powerline transitions
# Segment 1: Model (green/yellow bg)
echo -n "${model_bg}${FG_BLACK}${BOLD} ${ICON_ROBOT} $model ${RESET}"

# Separator: model -> cwd (model_fg on blue bg)
echo -n "${model_fg}${BG_BLUE}${SEP}${RESET}"

# Segment 2: CWD (blue bg)
echo -n "${BG_BLUE}${FG_BLACK} ${ICON_FOLDER} $dir_name ${RESET}"

if [ "$has_git" = true ]; then
  # Separator: cwd -> git (blue_fg on ltblue bg)
  echo -n "${FG_BLUE}${BG_LTBLUE}${SEP}${RESET}"
  # Segment 3: Git (ltblue bg)
  echo -n "${BG_LTBLUE}${FG_BLACK}${git_content}${RESET}"

  if [ "$has_context" = true ]; then
    # No arrow, just transition to context
    echo -n "${RESET} "
    # Segment 4: Context (dark bg)
    echo -n "${BG_DARK}${context_content}${RESET}"
  fi
else
  if [ "$has_context" = true ]; then
    # No arrow, just transition to context
    echo -n "${RESET} "
    # Segment: Context (dark bg)
    echo -n "${BG_DARK}${context_content}${RESET}"
  fi
fi
