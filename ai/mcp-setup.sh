#!/bin/sh
set -o errexit -o nounset

# ── Helpers ──────────────────────────────────────────────────────────────────

msg()  { echo "$(gum style --bold --foreground "#BE05D0" "  -") $1"; }
warn() { echo "$(gum style --bold --foreground "#FF9400" "  ⚠") $1"; }
ok()   { echo "$(gum style --bold --foreground "#00C853" "  ✓") $1"; }

# Read a key from macOS Keychain (empty string if not found)
keychain_get() {
    security find-generic-password -a "$1" -s "mcp-api-key" -w 2>/dev/null || true
}

# Store a key in macOS Keychain (update if exists)
keychain_set() {
    security delete-generic-password -a "$1" -s "mcp-api-key" 2>/dev/null || true
    security add-generic-password -a "$1" -s "mcp-api-key" -w "$2"
}

# Prompt for an API key with gum; skip if already in Keychain
prompt_key() {
    local name="$1"
    local label="$2"
    local existing
    existing=$(keychain_get "$name")

    if [ -n "$existing" ]; then
        ok "$label already in Keychain"
        eval "KEY_$name=\"$existing\""
        return 0
    fi

    local value
    value=$(gum input --password --prompt "$label: " --placeholder "paste key or leave blank to skip")

    if [ -z "$value" ]; then
        warn "Skipped $label (no key entered)"
        eval "KEY_$name="
        return 0
    fi

    keychain_set "$name" "$value"
    ok "$label stored in Keychain"
    eval "KEY_$name=\"$value\""
}

# ── Collect API keys ─────────────────────────────────────────────────────────

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup MCP servers")"
echo "  Keys are stored in macOS Keychain (encrypted)."
echo ""

prompt_key "exa"        "Exa API key"
prompt_key "context7"   "Context7 API key"
prompt_key "elevenlabs" "ElevenLabs API key"
prompt_key "openai"     "OpenAI API key"
prompt_key "gemini"     "Gemini API key"

# ── Claude Code MCP servers ─────────────────────────────────────────────────

msg "Configuring Claude Code MCP servers..."

if ! command -v claude >/dev/null 2>&1; then
    warn "claude CLI not found — skipping Claude MCP setup"
else
    # Remove stale entries (idempotent)
    for name in exa context7 ida mcp-tts; do
        claude mcp remove --scope user "$name" 2>/dev/null || true
    done

    # Exa — HTTP transport with API key in URL
    if [ -n "$KEY_exa" ]; then
        claude mcp add --scope user --transport http exa \
            "https://mcp.exa.ai/mcp?exaApiKey=${KEY_exa}"
        ok "Claude: exa (http)"
    fi

    # Context7 — stdio via npx
    if [ -n "$KEY_context7" ]; then
        claude mcp add --scope user context7 \
            -e CONTEXT7_API_KEY="$KEY_context7" \
            -- npx -y @upstash/context7-mcp
        ok "Claude: context7 (stdio)"
    fi

    # IDA Pro — stdio local binary (no key needed)
    if command -v ida-mcp >/dev/null 2>&1; then
        claude mcp add --scope user ida -- ida-mcp
        ok "Claude: ida (stdio)"
    else
        warn "ida-mcp not found — skipping (brew install blacktop/tap/ida-mcp)"
    fi

    # MCP TTS — stdio local binary
    if command -v mcp-tts >/dev/null 2>&1; then
        tts_env=""
        [ -n "$KEY_elevenlabs" ] && tts_env="$tts_env -e ELEVENLABS_API_KEY=$KEY_elevenlabs"
        [ -n "$KEY_openai" ]     && tts_env="$tts_env -e OPENAI_API_KEY=$KEY_openai"
        [ -n "$KEY_gemini" ]     && tts_env="$tts_env -e GEMINI_API_KEY=$KEY_gemini"
        eval claude mcp add --scope user mcp-tts $tts_env -- mcp-tts
        ok "Claude: mcp-tts (stdio)"
    else
        warn "mcp-tts not found — skipping (go install github.com/blacktop/mcp-tts@latest)"
    fi
fi

# ── Codex MCP servers ────────────────────────────────────────────────────────
# Append key-dependent MCP servers to the deployed config.toml only when
# the user provided credentials. This avoids leaving enabled servers with
# empty secrets.

CODEX_CONFIG="$HOME/.codex/config.toml"

if [ -f "$CODEX_CONFIG" ]; then
    msg "Configuring Codex MCP servers..."

    # Strip any previously appended MCP blocks (between sentinel comments)
    sed -i '' '/^# ── MCP-SETUP-BEGIN/,/^# ── MCP-SETUP-END/d' "$CODEX_CONFIG"

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
            [ -n "$KEY_openai" ]     && printf '%s"OPENAI_API_KEY"' "$sep"     && sep=", "
            [ -n "$KEY_gemini" ]     && printf '%s"GEMINI_API_KEY"' "$sep"
            printf ']\n'
            ok "Codex: mcp-tts" >&2
        fi

        echo ""
        echo "# ── MCP-SETUP-END ──"
    } >> "$CODEX_CONFIG"
fi

# ── Reminder ─────────────────────────────────────────────────────────────────

LOCALS_LINES=""
[ -n "$KEY_exa" ]        && LOCALS_LINES="$LOCALS_LINES
    set -gx EXA_API_KEY (security find-generic-password -a exa -s mcp-api-key -w 2>/dev/null)"
[ -n "$KEY_context7" ]   && LOCALS_LINES="$LOCALS_LINES
    set -gx CONTEXT7_API_KEY (security find-generic-password -a context7 -s mcp-api-key -w 2>/dev/null)"
[ -n "$KEY_elevenlabs" ] && LOCALS_LINES="$LOCALS_LINES
    set -gx ELEVENLABS_API_KEY (security find-generic-password -a elevenlabs -s mcp-api-key -w 2>/dev/null)"
[ -n "$KEY_openai" ]     && LOCALS_LINES="$LOCALS_LINES
    set -gx OPENAI_API_KEY (security find-generic-password -a openai -s mcp-api-key -w 2>/dev/null)"
[ -n "$KEY_gemini" ]     && LOCALS_LINES="$LOCALS_LINES
    set -gx GEMINI_API_KEY (security find-generic-password -a gemini -s mcp-api-key -w 2>/dev/null)"

echo ""
echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Done!")"

if [ -n "$LOCALS_LINES" ]; then
    echo ""
    echo "  Codex needs API keys exported in your shell environment."
    echo "  Add these to your $(gum style --bold "locals.fish") (reads from Keychain):"
    echo ""
    echo "$(gum style --faint "$LOCALS_LINES")"
fi
