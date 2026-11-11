#!/bin/bash
set -o errexit -o nounset

# ── Helpers ──────────────────────────────────────────────────────────────────

# shellcheck source=ai/lib.sh
. "$(dirname "$0")/lib.sh"

KEYCHAIN_SERVICE="dev.blacktop.ai-mcp-api-key"
LEGACY_KEYCHAIN_SERVICE="mcp-api-key"

# Retry inaccessible Keychain operations once after a user-approved unlock.
keychain_command() {
    local status
    if security "$@" 2>/dev/null; then return 0; else status=$?; fi
    # errSecItemNotFound (-25300) becomes exit status 44.
    if [ "$1" = find-generic-password ] && [ "$status" -eq 44 ]; then return 44; fi

    warn "macOS Keychain access failed (security exit $status)." >&2
    if [ -t 0 ] && [ -t 2 ] && gum confirm "Unlock the default keychain and retry?" >&2; then
        # security prompts for the password itself; setup never handles it.
        if security unlock-keychain >&2; then
            if security "$@" 2>/dev/null; then return 0; else status=$?; fi
            if [ "$1" = find-generic-password ] && [ "$status" -eq 44 ]; then return 44; fi
        fi
    fi
    warn "Run 'security unlock-keychain' in your Mac's terminal, then rerun 'bash ai/mcp-setup.sh'." >&2
    warn "If access still fails over SSH, run setup from the Mac's logged-in desktop session." >&2
    return 1
}

# Read a key from the specified service; only a missing item is an empty result.
keychain_get() {
    local status
    if keychain_command find-generic-password -a "$1" -s "$2" -w; then
        return 0
    else
        status=$?
    fi
    [ "$status" -eq 44 ]
}

# Store a key in macOS Keychain (update if exists)
keychain_set() {
    keychain_command add-generic-password -U -a "$1" -s "$KEYCHAIN_SERVICE" -w "$2"
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
    local existing
    existing=$(keychain_get "$name" "$KEYCHAIN_SERVICE") || return 1

    if [ -n "$env_value" ]; then
        if [ "$env_value" != "$existing" ]; then
            keychain_set "$name" "$env_value" || return 1
        fi
        ok "$label from \$$env_name (synced to Keychain)"
        printf -v "KEY_$name" '%s' "$env_value"
        return 0
    fi

    if [ -n "$existing" ]; then
        ok "$label already in Keychain"
        printf -v "KEY_$name" '%s' "$existing"
        return 0
    fi

    existing=$(keychain_get "$name" "$LEGACY_KEYCHAIN_SERVICE") || return 1
    if [ -n "$existing" ]; then
        keychain_set "$name" "$existing" || return 1
        ok "$label migrated to Keychain"
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

    keychain_set "$name" "$value" || return 1
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
