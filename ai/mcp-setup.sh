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

prompt_key "context7" "Context7 API key"
prompt_key "elevenlabs" "ElevenLabs API key"
prompt_key "openai" "OpenAI API key"
# GEMINI_API_KEY powers mcp-tts Google voices (the speak skill), not the Gemini CLI.
prompt_key "gemini" "Google AI API key (for TTS voices)"

# ── Claude Code MCP servers ─────────────────────────────────────────────────
# `claude mcp add --scope user` writes to $CLAUDE_CONFIG_DIR/.claude.json, so each
# variant is registered separately. Plain `claude` uses the default config file at
# ~/.claude.json (CLAUDE_CONFIG_DIR=$HOME); the -team/-ddb wrappers set
# CLAUDE_CONFIG_DIR to ~/.claude-team / ~/.claude-ddb (see their fish functions).
# Base-account MCP config lives in ~/.claude.json, NOT ~/.claude/.claude.json —
# pointing at ~/.claude here would write to a file the default `claude` never reads.

if ! command -v claude >/dev/null 2>&1; then
    warn "claude CLI not found — skipping Claude MCP setup"
else
    for variant in claude claude-team claude-ddb; do
        case "$variant" in
        claude) config_dir="$HOME" ;;
        *) config_dir="$HOME/.$variant" ;;
        esac
        [ -d "$config_dir" ] || continue
        export CLAUDE_CONFIG_DIR="$config_dir"
        msg "Configuring Claude Code MCP servers for $variant..."

        # Remove stale entries (idempotent)
        # Node REPL is project opt-in; never inherit a global user registration.
        for name in exa context7 ida mcp-tts node_repl node-repl; do
            claude mcp remove --scope user "$name" 2>/dev/null || true
        done

        # Exa — public keyless HTTP endpoint.
        # Do not pass an Exa API key here; the free-key path rate-limits quickly.
        claude mcp add --scope user --transport http exa https://mcp.exa.ai/mcp
        ok "$variant: exa (http, keyless)"

        # Context7 — stdio via npx
        if [ -n "$KEY_context7" ]; then
            claude mcp add --scope user context7 \
                -e CONTEXT7_API_KEY="$KEY_context7" \
                -- npx -y @upstash/context7-mcp@4.1.1
            ok "$variant: context7 (stdio)"
        fi

        # IDA Pro — stdio local binary (no key needed)
        if [ -x /opt/homebrew/bin/ida-mcp ]; then
            claude mcp add --scope user ida -- /opt/homebrew/bin/ida-mcp
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

# ── Reminder ─────────────────────────────────────────────────────────────────

LOCALS_LINES=""
[ -n "$KEY_context7" ] && LOCALS_LINES="$LOCALS_LINES
    set -gx CONTEXT7_API_KEY (security find-generic-password -a context7 -s $KEYCHAIN_SERVICE -w 2>/dev/null)"
[ -n "$KEY_elevenlabs" ] && LOCALS_LINES="$LOCALS_LINES
    set -gx ELEVENLABS_API_KEY (security find-generic-password -a elevenlabs -s $KEYCHAIN_SERVICE -w 2>/dev/null)"
[ -n "$KEY_openai" ] && LOCALS_LINES="$LOCALS_LINES
    set -gx OPENAI_API_KEY (security find-generic-password -a openai -s $KEYCHAIN_SERVICE -w 2>/dev/null)"
[ -n "$KEY_gemini" ] && LOCALS_LINES="$LOCALS_LINES
    set -gx GEMINI_API_KEY (security find-generic-password -a gemini -s $KEYCHAIN_SERVICE -w 2>/dev/null)"

echo ""
ok "MCP servers configured"

if [ -n "$LOCALS_LINES" ]; then
    echo ""
    echo "  Codex needs API keys exported in your shell environment."
    echo "  Add these to your $(gum style --bold "locals.fish") (reads from Keychain):"
    echo ""
    gum style --faint "$LOCALS_LINES"
fi
