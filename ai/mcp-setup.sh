#!/bin/bash
set -o errexit -o nounset

# ── Helpers ──────────────────────────────────────────────────────────────────

# shellcheck source=ai/lib.sh
. "$(dirname "$0")/lib.sh"

KEYCHAIN_SERVICE="dev.blacktop.ai-mcp-api-key"
LEGACY_KEYCHAIN_SERVICE="mcp-api-key"

# Read a key from macOS Keychain (empty string if not found)
keychain_get() {
    security find-generic-password -a "$1" -s "$KEYCHAIN_SERVICE" -w 2>/dev/null ||
        security find-generic-password -a "$1" -s "$LEGACY_KEYCHAIN_SERVICE" -w 2>/dev/null ||
        true
}

# Store a key in macOS Keychain (update if exists)
keychain_set() {
    security delete-generic-password -a "$1" -s "$KEYCHAIN_SERVICE" 2>/dev/null || true
    security add-generic-password -a "$1" -s "$KEYCHAIN_SERVICE" -w "$2"
}

# Resolve an API key from (in order): $<NAME>_API_KEY env var, macOS Keychain, gum prompt.
# Env-var values are synced to Keychain so subsequent runs work without the env exported.
prompt_key() {
    local name="$1"
    local label="$2"
    local env_name
    env_name="$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')_API_KEY"
    local env_value=""
    env_value="${!env_name:-}"

    if [ -n "$env_value" ]; then
        keychain_set "$name" "$env_value"
        ok "$label from \$$env_name (synced to Keychain)"
        printf -v "KEY_$name" '%s' "$env_value"
        return 0
    fi

    local existing
    existing=$(keychain_get "$name")
    if [ -n "$existing" ]; then
        keychain_set "$name" "$existing"
        ok "$label already in Keychain"
        printf -v "KEY_$name" '%s' "$existing"
        return 0
    fi

    local value
    value=$(gum input --password --prompt "$label: " --placeholder "paste key or leave blank to skip")
    if [ -z "$value" ]; then
        warn "Skipped $label (no key entered)"
        printf -v "KEY_$name" '%s' ""
        return 0
    fi

    keychain_set "$name" "$value"
    ok "$label stored in Keychain"
    printf -v "KEY_$name" '%s' "$value"
}

# ── Collect API keys ─────────────────────────────────────────────────────────

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup MCP servers")"
echo "  Keys are stored in macOS Keychain (encrypted)."
echo ""

prompt_key "exa" "Exa API key"
prompt_key "context7" "Context7 API key"
prompt_key "elevenlabs" "ElevenLabs API key"
prompt_key "openai" "OpenAI API key"
prompt_key "gemini" "Gemini API key"

# ── Claude Code MCP servers ─────────────────────────────────────────────────
# `claude mcp add --scope user` writes to $CLAUDE_CONFIG_DIR/.claude.json,
# so each variant must be registered separately.

if ! command -v claude >/dev/null 2>&1; then
    warn "claude CLI not found — skipping Claude MCP setup"
else
    for variant in claude claude-team; do
        config_dir="$HOME/.$variant"
        [ -d "$config_dir" ] || continue
        export CLAUDE_CONFIG_DIR="$config_dir"
        msg "Configuring Claude Code MCP servers for $variant..."

        # Remove stale entries (idempotent)
        for name in exa context7 ida mcp-tts; do
            claude mcp remove --scope user "$name" 2>/dev/null || true
        done

        # Exa — stdio keeps the API key out of the MCP URL persisted by Claude.
        if [ -n "$KEY_exa" ]; then
            claude mcp add --scope user exa \
                -e EXA_API_KEY="$KEY_exa" \
                -- npx -y exa-mcp-server
            ok "$variant: exa (stdio)"
        fi

        # Context7 — stdio via npx
        if [ -n "$KEY_context7" ]; then
            claude mcp add --scope user context7 \
                -e CONTEXT7_API_KEY="$KEY_context7" \
                -- npx -y @upstash/context7-mcp
            ok "$variant: context7 (stdio)"
        fi

        # IDA Pro — stdio local binary (no key needed)
        if command -v ida-mcp >/dev/null 2>&1; then
            claude mcp add --scope user ida -- ida-mcp
            ok "$variant: ida (stdio)"
        else
            warn "ida-mcp not found — skipping (brew install blacktop/tap/ida-mcp)"
        fi

        # MCP TTS — stdio local binary
        if command -v mcp-tts >/dev/null 2>&1; then
            set --
            [ -n "$KEY_elevenlabs" ] && set -- "$@" -e "ELEVENLABS_API_KEY=$KEY_elevenlabs"
            [ -n "$KEY_openai" ] && set -- "$@" -e "OPENAI_API_KEY=$KEY_openai"
            [ -n "$KEY_gemini" ] && set -- "$@" -e "GEMINI_API_KEY=$KEY_gemini"
            claude mcp add --scope user mcp-tts "$@" -- mcp-tts
            ok "$variant: mcp-tts (stdio)"
        else
            warn "mcp-tts not found — skipping (go install github.com/blacktop/mcp-tts@latest)"
        fi
    done
    unset CLAUDE_CONFIG_DIR
fi

# ── Codex MCP servers ────────────────────────────────────────────────────────
# Append key-dependent MCP servers to the deployed config.toml only when
# the user provided credentials. This avoids leaving enabled servers with
# empty secrets. The same block is mirrored to ~/.codex and ~/.codex-team.

msg "Configuring Codex MCP servers..."

# Build the MCP block once (logging to stderr, content to the tempfile)
mcp_block=$(mktemp -t codex-mcp-block)
{
    echo ""
    echo "# ── MCP-SETUP-BEGIN (managed by mcp-setup.sh — do not edit) ──"

    if [ -n "$KEY_exa" ]; then
        cat <<'TOML'

[mcp_servers.exa]
command = "npx"
args = ["-y", "exa-mcp-server"]
env_vars = ["EXA_API_KEY"]
TOML
        ok "Codex: exa" >&2
    fi

    if [ -n "$KEY_context7" ]; then
        cat <<'TOML'

[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
env_vars = ["CONTEXT7_API_KEY"]
TOML
        ok "Codex: context7" >&2
    fi

    if [ -n "$KEY_elevenlabs" ] || [ -n "$KEY_openai" ] || [ -n "$KEY_gemini" ]; then
        printf '\n[mcp_servers.mcp_tts]\ncommand = "mcp-tts"\nargs = ["--verbose"]\nenv_vars = ['
        sep=""
        [ -n "$KEY_elevenlabs" ] && printf '%s"ELEVENLABS_API_KEY"' "$sep" && sep=", "
        [ -n "$KEY_openai" ] && printf '%s"OPENAI_API_KEY"' "$sep" && sep=", "
        [ -n "$KEY_gemini" ] && printf '%s"GEMINI_API_KEY"' "$sep"
        printf ']\n\n[mcp_servers.mcp_tts.tools.say_tts]\napproval_mode = "approve"\n'
        ok "Codex: mcp-tts" >&2
    fi

    echo ""
    echo "# ── MCP-SETUP-END ──"
} >"$mcp_block"

for variant in codex codex-team; do
    config="$HOME/.$variant/config.toml"
    [ -f "$config" ] || continue
    # Strip any previously appended MCP blocks (between sentinel comments)
    sed -i '' '/^# ── MCP-SETUP-BEGIN/,/^# ── MCP-SETUP-END/d' "$config"
    cat "$mcp_block" >>"$config"
done
rm -f "$mcp_block"

# ── Reminder ─────────────────────────────────────────────────────────────────

LOCALS_LINES=""
[ -n "$KEY_exa" ] && LOCALS_LINES="$LOCALS_LINES
    set -gx EXA_API_KEY (security find-generic-password -a exa -s $KEYCHAIN_SERVICE -w 2>/dev/null)"
[ -n "$KEY_context7" ] && LOCALS_LINES="$LOCALS_LINES
    set -gx CONTEXT7_API_KEY (security find-generic-password -a context7 -s $KEYCHAIN_SERVICE -w 2>/dev/null)"
[ -n "$KEY_elevenlabs" ] && LOCALS_LINES="$LOCALS_LINES
    set -gx ELEVENLABS_API_KEY (security find-generic-password -a elevenlabs -s $KEYCHAIN_SERVICE -w 2>/dev/null)"
[ -n "$KEY_openai" ] && LOCALS_LINES="$LOCALS_LINES
    set -gx OPENAI_API_KEY (security find-generic-password -a openai -s $KEYCHAIN_SERVICE -w 2>/dev/null)"
[ -n "$KEY_gemini" ] && LOCALS_LINES="$LOCALS_LINES
    set -gx GEMINI_API_KEY (security find-generic-password -a gemini -s $KEYCHAIN_SERVICE -w 2>/dev/null)"

echo ""
echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Done!")"

if [ -n "$LOCALS_LINES" ]; then
    echo ""
    echo "  Codex needs API keys exported in your shell environment."
    echo "  Add these to your $(gum style --bold "locals.fish") (reads from Keychain):"
    echo ""
    gum style --faint "$LOCALS_LINES"
fi
