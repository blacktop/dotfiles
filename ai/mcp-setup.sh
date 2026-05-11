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

        # Exa — public keyless HTTP endpoint.
        # Do not pass an Exa API key here; the free-key path rate-limits quickly.
        claude mcp add --scope user --transport http exa https://mcp.exa.ai/mcp
        ok "$variant: exa (http, keyless)"

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

sync_codex_mcp_config() {
    local variant="$1"
    local config="$2"
    local template="$3"
    local tmp

    [ -f "$config" ] || return 0

    tmp=$(mktemp)
    if python3 - "$config" "$template" "$HOME" >"$tmp" <<'PY'
import re
import sys

config_path, template_path, home = sys.argv[1:4]
table_re = re.compile(r"^\s*\[{1,2}([^\]]+)\]{1,2}\s*(?:#.*)?$")


def table_name(line):
    match = table_re.match(line)
    if not match:
        return None
    return match.group(1).strip()


def is_mcp_table(name):
    return name.startswith("mcp_servers.")


with open(template_path, encoding="utf-8") as fh:
    template_lines = [line.replace("${HOME}", home) for line in fh]

managed_lines = []
managed_tables = set()
capturing = False

for line in template_lines:
    name = table_name(line)
    if name is not None:
        if is_mcp_table(name):
            capturing = True
            managed_tables.add(name)
        elif capturing:
            break

    if capturing:
        managed_lines.append(line)

if not managed_tables:
    raise SystemExit(f"no [mcp_servers.*] tables found in {template_path}")

managed_prefixes = tuple(f"{name}." for name in managed_tables)


def is_managed_table(name):
    return name in managed_tables or name.startswith(managed_prefixes)


with open(config_path, encoding="utf-8") as fh:
    lines = fh.readlines()

out = []
in_legacy_block = False
in_target_table = False
insert_index = None

for line in lines:
    if line.startswith("# ── MCP-SETUP-BEGIN"):
        if insert_index is None:
            insert_index = len(out)
        in_legacy_block = True
        continue

    if in_legacy_block:
        if line.startswith("# ── MCP-SETUP-END"):
            in_legacy_block = False
        continue

    name = table_name(line)
    if name is not None:
        if is_managed_table(name):
            if insert_index is None:
                insert_index = len(out)
            in_target_table = True
            continue
        in_target_table = False

    if in_target_table:
        continue

    out.append(line)

if insert_index is None:
    while out and not out[-1].strip():
        out.pop()
    out.extend(["\n"] if out else [])
    out.extend(managed_lines)
else:
    out[insert_index:insert_index] = managed_lines

sys.stdout.writelines(out)
PY
    then
        mv "$tmp" "$config"
        ok "Codex: synced MCP servers for $variant"
    else
        rm -f "$tmp"
        warn "Codex: failed to sync MCP servers for $variant"
    fi
}

# ── Codex MCP servers ────────────────────────────────────────────────────────
# Keep deployed Codex configs current even when ai/setup.sh preserves an
# existing user-edited config.toml instead of copying the template.

for variant in codex codex-team; do
    config="$HOME/.$variant/config.toml"
    sync_codex_mcp_config "$variant" "$config" "$(dirname "$0")/codex/config.toml"
done

# ── Gemini CLI MCP servers ───────────────────────────────────────────────────
# Patch ~/.gemini/settings.json to register the keyless Exa endpoint.
# (Gemini's settings.json is user-owned; we merge with jq instead of overwriting.)

gemini_settings="$HOME/.gemini/settings.json"
if command -v jq >/dev/null 2>&1; then
    msg "Configuring Gemini MCP servers..."
    mkdir -p "$(dirname "$gemini_settings")"
    if [ ! -f "$gemini_settings" ]; then
        printf '{\n  "mcpServers": {}\n}\n' >"$gemini_settings"
        ok "Gemini: created settings.json"
    fi
    tmp=$(mktemp)
    if jq '.mcpServers = (.mcpServers // {}) | .mcpServers.exa = {"httpUrl": "https://mcp.exa.ai/mcp"}' "$gemini_settings" >"$tmp"; then
        mv "$tmp" "$gemini_settings"
        ok "Gemini: exa (http, keyless)"
    else
        warn "Gemini: failed to patch settings.json (kept original)"
        rm -f "$tmp"
    fi
else
    warn "jq not found — skipping Gemini MCP setup"
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
echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Done!")"

if [ -n "$LOCALS_LINES" ]; then
    echo ""
    echo "  Codex needs API keys exported in your shell environment."
    echo "  Add these to your $(gum style --bold "locals.fish") (reads from Keychain):"
    echo ""
    gum style --faint "$LOCALS_LINES"
fi
