#!/bin/bash
# Claude Code statusline — minimal, no background fills
set -euo pipefail

input=$(cat)

if ! echo "$input" | jq -e . >/dev/null 2>&1; then
    exit 0
fi

# ── colors (Rosé Pine truecolor, foreground only, rendered dim by Claude Code) ─
RESET=$'\033[0m'
C_MUTED=$'\033[38;2;110;106;134m' # muted #6e6a86 — separators
C_BASE=$'\033[38;2;224;222;244m'  # text  #e0def4 — default text
C_ROSE=$'\033[38;2;235;188;186m'  # rose  #ebbcba — model / dir
C_IRIS=$'\033[38;2;196;167;231m'  # iris  #c4a7e7 — clean git
C_GOLD=$'\033[38;2;246;193;119m'  # gold  #f6c177 — dirty git / context warning
C_LOVE=$'\033[38;2;235;111;146m'  # love  #eb6f92 — high context / conflict / INSERT mode
C_PINE=$'\033[38;2;49;116;143m'   # pine  #31748f — agent / worktree / NORMAL mode accent
C_FOAM=$'\033[38;2;156;207;216m'  # foam  #9ccfd8 — ddb / custom variant

SEP="${C_MUTED}·${RESET}"

# ── extract fields (single jq pass) ───────────────────────────────────────────
# Unit separator, not tab: bash collapses runs of whitespace IFS, which would
# swallow empty fields and shift every value one slot to the left.
IFS=$'\037' read -r cwd model effort vim_mode agent_name pr_number pr_state \
    pct five_pct week_pct session_id < <(echo "$input" | jq -r '
      def s(f): (f // "") | tostring;
      [ s(.workspace.current_dir)
      , (if (.model | type) == "object" then (.model.display_name // .model.id // "claude")
         elif (.model | type) == "string" then .model
         else "claude" end)
      , s(.effort.level)
      , s(.vim.mode)
      , s(.agent.name)
      , s(.pr.number)
      , s(.pr.review_state)
      , s(.context_window.used_percentage)
      , s(.rate_limits.five_hour.used_percentage)
      , s(.rate_limits.seven_day.used_percentage)
      , s(.session_id // .session.id)
      ] | join("\u001f")') || true

# "Opus 5 (1M context)" -> opus-5, "claude-haiku-4-5-20251001" -> haiku-4-5
model=$(printf '%s' "${model:-claude}" | tr '[:upper:]' '[:lower:]' | sed -E '
  s/\([^)]*\)//g
  s/\[[^]]*\]//g
  s/^claude[- ]+//
  s/-?[0-9]{8}$//
  s/[[:space:]]+/-/g
  s/^-+//; s/-+$//')
[ -n "$effort" ] && model="${model}/${effort}"

# ── location: repo name (+ subdir), branch shown once ─────────────────────────
# In a linked worktree the dir, worktree and branch names are usually the same
# string; show the repo it belongs to plus a single "wt:" tagged branch.
loc_part=""
branch_part=""
conflict_part=""
if [ -n "$cwd" ] && git_paths=$(git -C "$cwd" rev-parse --path-format=absolute \
    --git-dir --git-common-dir --show-toplevel 2>/dev/null); then
    {
        read -r git_dir
        read -r common_dir
        read -r toplevel
    } <<<"$git_paths"

    repo_root=${common_dir%/.git}
    repo=${repo_root##*/}
    repo=${repo%.git}
    rel=${cwd#"$toplevel"}
    rel=${rel#/}
    loc_part="${C_BASE}${repo}${rel:+/$rel}${RESET}"

    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

    porcelain=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" status --porcelain 2>/dev/null)
    staged=$(echo "$porcelain" | grep -c '^[MADRC]' || true)
    modified=$(echo "$porcelain" | grep -c '^.[MD]' || true)
    ahead=$(git -C "$cwd" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)

    flags=""
    [ "${ahead:-0}" -gt 0 ] && flags+="⇡${ahead}"
    [ "${behind:-0}" -gt 0 ] && flags+="⇣${behind}"
    [ "${staged:-0}" -gt 0 ] && flags+="+${staged}"
    [ "${modified:-0}" -gt 0 ] && flags+="!${modified}"

    branch_color=$C_IRIS
    [ -n "$flags" ] && branch_color=$C_GOLD
    prefix=""
    [ "$git_dir" != "$common_dir" ] && prefix="${C_PINE}wt:${RESET}"
    branch_part="${prefix}${branch_color}${branch}${flags:+ ${flags}}${RESET}"

    if [ -f "$git_dir/MERGE_HEAD" ]; then
        conflict_part="${C_LOVE}✗merge${RESET}"
    elif [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
        conflict_part="${C_LOVE}✗rebase${RESET}"
    fi
else
    dir_name=${cwd##*/}
    [ "$cwd" = "$HOME" ] && dir_name="~"
    [ -n "$dir_name" ] && loc_part="${C_BASE}${dir_name}${RESET}"
fi

# ── context + telemetry (read by the high-tide skill) ─────────────────────────
# One file per session, keyed by session_id. A single shared file would be
# overwritten by whichever pane rendered last, and a reader has no way to tell
# whose usage it got — a worker at 5% would happily read a PM at 95%.
ctx_part=""
if [ -n "$pct" ] && [ -n "$session_id" ]; then
    telemetry_root="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    telemetry_dir="$telemetry_root/statusline/by-session"
    telemetry_file="$telemetry_dir/${session_id}.json"
    telemetry_tmp="$telemetry_file.$$"
    telemetry_time=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date)
    telemetry_new=1
    [ -f "$telemetry_file" ] && telemetry_new=0
    if mkdir -p "$telemetry_dir" 2>/dev/null; then
        # Once per session, not per render: drop last week's sessions and any
        # temp files orphaned by a killed render.
        if [ "$telemetry_new" = 1 ]; then
            find "$telemetry_dir" -name '*.json' -mtime +7 -delete 2>/dev/null || true
            find "$telemetry_dir" -name '*.json.[0-9]*' -mtime +1 -delete 2>/dev/null || true
        fi
        old_umask=$(umask)
        umask 077
        if echo "$input" | jq -c --arg generated_at "$telemetry_time" '
          {
            source: "claude-statusline",
            generated_at: $generated_at,
            context_window: (.context_window // {}),
            workspace: {
              current_dir: (.workspace.current_dir // null),
              project_dir: (.workspace.project_dir // null),
              git_worktree: (.workspace.git_worktree // null)
            },
            model:
              (if (.model | type) == "object" then
                { id: (.model.id // null), display_name: (.model.display_name // null) }
              else
                .model
              end),
            effort: (.effort // null),
            thinking: (.thinking // null),
            agent: { name: (.agent.name // null) },
            worktree: { branch: (.worktree.branch // .worktree.name // null) },
            session_id: (.session_id // .session.id // null),
            session_name: (.session_name // null),
            pr: (.pr // null),
            transcript_path: (.transcript_path // null)
          }
        ' >"$telemetry_tmp" 2>/dev/null; then
            mv "$telemetry_tmp" "$telemetry_file" 2>/dev/null || rm -f "$telemetry_tmp"
            chmod 600 "$telemetry_file" 2>/dev/null || true
        else
            rm -f "$telemetry_tmp"
        fi
        umask "$old_umask"
    fi
fi

if [ -n "$pct" ]; then
    pct_int=$(printf '%.0f' "$pct" 2>/dev/null || echo "$pct")
    if [ "${pct_int:-0}" -gt 85 ]; then
        ctx_color=$C_LOVE
    elif [ "${pct_int:-0}" -gt 65 ]; then
        ctx_color=$C_GOLD
    else
        ctx_color=$C_MUTED
    fi
    ctx_part="${ctx_color}ctx:${pct_int}%${RESET}"
fi

# ── rate limits (claude.ai subscribers) ───────────────────────────────────────
rate_part=""
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
    rate_str=""
    [ -n "$five_pct" ] && rate_str+="5h:$(printf '%.0f' "$five_pct")%"
    [ -n "$week_pct" ] && rate_str+="${rate_str:+ }7d:$(printf '%.0f' "$week_pct")%"
    rate_part="${C_MUTED}${rate_str}${RESET}"
fi

# ── assemble ───────────────────────────────────────────────────────────────────
parts=()

# variant label first (far left) — from CLAUDE_CONFIG_DIR; nothing for plain ~/.claude
_cfg="${CLAUDE_CONFIG_DIR:-}"
if [ -n "$_cfg" ]; then
    _base=$(basename "$_cfg")
    case "$_base" in
    .claude) ;; # default, no label
    .claude-team) parts+=("${C_GOLD}team${RESET}") ;;
    .claude-ddb) parts+=("${C_FOAM}ddb${RESET}") ;;
    .claude-*) parts+=("${C_PINE}${_base#.claude-}${RESET}") ;;
    esac
fi

# vim mode (only when active)
case "$vim_mode" in
"") ;;
INSERT) parts+=("${C_LOVE}I${RESET}") ;;
NORMAL) parts+=("${C_PINE}N${RESET}") ;;
*) parts+=("${C_MUTED}${vim_mode}${RESET}") ;;
esac

parts+=("${C_ROSE}${model}${RESET}")

[ -n "$loc_part" ] && parts+=("$loc_part")
[ -n "$branch_part" ] && parts+=("$branch_part")
[ -n "$conflict_part" ] && parts+=("$conflict_part")
[ -n "$agent_name" ] && parts+=("${C_PINE}@${agent_name}${RESET}")

# pull request and review state
if [ -n "$pr_number" ]; then
    case "$pr_state" in
    approved) parts+=("${C_IRIS}pr:#${pr_number}✓${RESET}") ;;
    changes_requested) parts+=("${C_LOVE}pr:#${pr_number}!${RESET}") ;;
    draft) parts+=("${C_MUTED}pr:#${pr_number}◌${RESET}") ;;
    pending) parts+=("${C_GOLD}pr:#${pr_number}?${RESET}") ;;
    *) parts+=("${C_BASE}pr:#${pr_number}${RESET}") ;;
    esac
fi

[ -n "$ctx_part" ] && parts+=("$ctx_part")
[ -n "$rate_part" ] && parts+=("$rate_part")

out=""
for part in "${parts[@]}"; do
    [ -n "$out" ] && out+=" ${SEP} "
    out+="$part"
done

printf '%s' "$out"
