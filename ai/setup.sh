#!/bin/sh
set -o errexit -o nounset

# ── Args / env ───────────────────────────────────────────────────────────────
# Default: preserve existing user-mutable configs (settings.json, config.toml).
# Use --force or AI_FORCE_SYNC=1 to overwrite them with the dotfile template.
FORCE_SYNC="${AI_FORCE_SYNC:-0}"
case "${1:-}" in
--force | -f) FORCE_SYNC=1 ;;
--help | -h)
    cat <<EOF
Usage: $0 [--force|-f]

Idempotent by default — re-running preserves your customised:
  ~/.claude/settings.json
  ~/.codex/config.toml

Use --force (or AI_FORCE_SYNC=1) to overwrite those with the dotfile template.
Static content (CLAUDE.md, agents/, commands/, prompts/, statusline.sh) and
managed MCP blocks always sync.
EOF
    exit 0
    ;;
esac

# ── Helpers ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(dirname "$0")"
# shellcheck source=ai/lib.sh
. "$SCRIPT_DIR/lib.sh"

install_npm_global_if_needed() {
    pkg="$1"
    cmd="$2"

    if ! command -v npm >/dev/null 2>&1; then
        warn "npm not found — skipping $pkg"
        return 0
    fi

    npm_installed=0
    if npm list -g "$pkg" --depth=0 >/dev/null 2>&1; then
        npm_installed=1
    fi

    old_version=""
    if command -v "$cmd" >/dev/null 2>&1; then
        old_version="$("$cmd" --version 2>/dev/null || true)"
    fi

    outdated=""
    outdated="$(npm outdated -g "$pkg" 2>/dev/null)" && outdated_status=0 || outdated_status=$?
    if [ "$npm_installed" = "1" ] && [ -n "$old_version" ] && [ -z "$outdated" ]; then
        if [ "$outdated_status" -eq 0 ]; then
            ok "$cmd $old_version up to date"
        else
            warn "Could not check $pkg updates; keeping $cmd $old_version"
        fi
        return 0
    fi

    msg "Install $pkg (npm)..."
    if npm install -g "$pkg"; then
        new_version=""
        if command -v "$cmd" >/dev/null 2>&1; then
            new_version="$("$cmd" --version 2>/dev/null || true)"
        fi
        if [ -n "$new_version" ] && [ "$old_version" != "$new_version" ]; then
            ok "$cmd: ${old_version:-not installed} -> $new_version"
        else
            ok "$pkg installed"
        fi
    else
        warn "Failed to install $pkg — continuing setup"
    fi
}

add_claude_marketplace() {
    variant="$1"
    marketplace="$2"
    source="$3"

    if claude plugin marketplace list --json 2>/dev/null | grep -q "\"name\": \"$marketplace\""; then
        return 0
    fi

    if claude plugin marketplace add "$source" 2>/dev/null; then
        return 0
    fi

    if claude plugin marketplace list --json 2>/dev/null | grep -q "\"name\": \"$marketplace\""; then
        return 0
    fi

    warn "$variant: failed to add $marketplace marketplace"
    return 1
}

install_claude_plugin() {
    variant="$1"
    plugin="$2"
    note="$3"

    if claude plugin install "$plugin" 2>/dev/null; then
        return 0
    fi

    if [ -n "$note" ]; then
        warn "$variant: failed to install $plugin ($note)"
    else
        warn "$variant: failed to install $plugin"
    fi
}

# Sync a user-mutable file. Skip if dest exists unless FORCE_SYNC=1.
# Args: description, src, dst
sync_user_file() {
    desc="$1" src="$2" dst="$3"
    if [ -f "$dst" ] && [ "$FORCE_SYNC" != "1" ]; then
        if cmp -s "$src" "$dst"; then
            ok "$desc up to date"
        else
            warn "Skipped $desc (exists & differs — review with: diff '$src' '$dst')"
            warn "    re-run with --force to overwrite"
        fi
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    ok "Wrote $desc"
}

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup AI CLI agents")"
[ "$FORCE_SYNC" = "1" ] && warn "FORCE mode: user-mutable configs will be overwritten"

# Install CLI agents
install_npm_global_if_needed "@anthropic-ai/claude-code" "claude"

install_npm_global_if_needed "@openai/codex" "codex"
msg "Install codex GUI cask..."
brew install --quiet codex-app

msg "Install gemini-cli..."
brew install --quiet gemini-cli

# Install skill dependencies
echo "$(gum style --bold --foreground "#BE05D0" "  -") Install ralph-tui..."
if command -v bun >/dev/null 2>&1; then
    if ! bun install -g ralph-tui; then
        warn "Failed to install ralph-tui with bun — continuing setup"
    fi
else
    warn "bun not found — skipping ralph-tui"
fi

# Create config directories (including unified ~/.agents for skills)
mkdir -p "$HOME/.claude" "$HOME/.claude-team" "$HOME/.codex" "$HOME/.codex-team" "$HOME/.gemini" "$HOME/.agents/skills"

# Sync claude + claude-team from the same source tree (settings.json gated by FORCE_SYNC)
for variant in claude claude-team; do
    msg "Sync $variant config..."
    rsync -a --exclude='.DS_Store' --exclude='skills' --exclude='settings.json' \
        "$SCRIPT_DIR/claude/" "$HOME/.$variant/"
    sync_user_file "$variant settings.json" \
        "$SCRIPT_DIR/claude/settings.json" "$HOME/.$variant/settings.json"
done

# Sync codex + codex-team from the same source tree (config.toml gated by FORCE_SYNC).
# Codex TOML doesn't expand env vars — render ${HOME} placeholders before installing.
codex_tmp=$(mktemp -t codex-config.toml)
sed "s|\${HOME}|$HOME|g" "$SCRIPT_DIR/codex/config.toml" >"$codex_tmp"
for variant in codex codex-team; do
    msg "Sync $variant config..."
    rsync -a --exclude='.DS_Store' --exclude='skills' --exclude='config.toml' \
        "$SCRIPT_DIR/codex/" "$HOME/.$variant/"
    sync_user_file "$variant config.toml" "$codex_tmp" "$HOME/.$variant/config.toml"
done
rm -f "$codex_tmp"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync gemini config..."
rsync -a --exclude='.DS_Store' --exclude='skills' "$SCRIPT_DIR/gemini/" "$HOME/.gemini/"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Sync skills..."
"$SCRIPT_DIR/sync-skills.sh"

# Install Gemini CLI extensions
echo "$(gum style --bold --foreground "#BE05D0" "  -") Install gemini extensions..."
"$SCRIPT_DIR/gemini/install-extensions.sh"

# Install Claude Code plugin marketplaces and plugins
# `claude plugin` writes to $CLAUDE_CONFIG_DIR/plugins/, so each variant needs its own pass.
if command -v claude >/dev/null 2>&1; then
    echo "$(gum style --bold --foreground "#BE05D0" "  -") Install claude plugins..."
    for variant in claude claude-team; do
        config_dir="$HOME/.$variant"
        [ -d "$config_dir" ] || continue
        export CLAUDE_CONFIG_DIR="$config_dir"

        if add_claude_marketplace "$variant" "claude-plugins-official" "anthropics/claude-plugins-official"; then
            install_claude_plugin "$variant" "rust-analyzer-lsp@claude-plugins-official" ""
            install_claude_plugin "$variant" "gopls-lsp@claude-plugins-official" ""
            install_claude_plugin "$variant" "frontend-design@claude-plugins-official" ""
            install_claude_plugin "$variant" "skill-creator@claude-plugins-official" ""
            install_claude_plugin "$variant" "pr-review-toolkit@claude-plugins-official" "/review-pr and /fix-issue depend on it"
            install_claude_plugin "$variant" "plugin-dev@claude-plugins-official" ""
        fi

        if add_claude_marketplace "$variant" "openai-codex" "openai/codex-plugin-cc"; then
            install_claude_plugin "$variant" "codex@openai-codex" "/codex:review and /codex:rescue depend on it"
        fi

        flow_marketplace="$HOME/Developer/Mine/blacktop/workflow"
        if [ -d "$flow_marketplace/.claude-plugin" ]; then
            if add_claude_marketplace "$variant" "blacktop-flow" "$flow_marketplace"; then
                install_claude_plugin "$variant" "flow@blacktop-flow" ""
            fi
        else
            warn "$variant: blacktop-flow marketplace missing at $flow_marketplace"
        fi
    done
    unset CLAUDE_CONFIG_DIR
else
    gum style --faint "      ⚠ claude CLI not found, skipping plugin install"
fi

# Setup MCP servers (API keys → Keychain, register with Claude + Codex)
"$SCRIPT_DIR/mcp-setup.sh"
