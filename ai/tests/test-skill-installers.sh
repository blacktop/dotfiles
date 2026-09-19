#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname "$0")/../.." && pwd)
scratch=$(mktemp -d "${TMPDIR:-/tmp}/skill-installers.XXXXXX")
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
mkdir "$scratch/bin"

cat > "$scratch/bin/gum" <<'SH'
#!/bin/sh
printf '%s\n' "$*"
SH
cat > "$scratch/bin/npx" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$CALL_LOG"
if [ "${DISABLE_TELEMETRY:-}" != 1 ] || [ "${DO_NOT_TRACK:-}" != 1 ]; then
    echo 'installer telemetry opt-out missing' >&2
    exit 90
fi
if [ "$1" != -y ] || [ "$2" != skills@1.7.0 ] || [ "$3" != add ]; then
    echo 'unexpected installer/version' >&2
    exit 91
fi
case " $* " in
    *" --skill ${FAIL_SKILL:-never-fail} "*)
        echo 'upstream install diagnostic' >&2
        exit 42
        ;;
esac
SH
cat > "$scratch/bin/claude" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$CALL_LOG"
echo 'plugin install diagnostic' >&2
exit 43
SH
chmod +x "$scratch/bin/"*
PATH="$scratch/bin:$PATH"
export PATH
CALL_LOG="$scratch/calls"
export CALL_LOG

DISABLE_TELEMETRY='' DO_NOT_TRACK='' sh "$root/ai/skills/install-community.sh" > "$scratch/success.out" 2> "$scratch/success.err"
[ "$(wc -l < "$CALL_LOG" | tr -d ' ')" = 29 ]
grep -Fqx -- '-y skills@1.7.0 add https://github.com/anthropics/skills --skill frontend-design --agent amp -g -y' "$CALL_LOG"
grep -Fqx -- '-y skills@1.7.0 add https://github.com/anomalyco/opentui --skill opentui --agent amp -g -y' "$CALL_LOG"
grep -Fqx -- '-y skills@1.7.0 add https://github.com/leonxlnx/taste-skill --agent amp -g -y' "$CALL_LOG"
if grep -Eq 'discover-tui|ask-questions-if-underspecified|skill-improver|c-review|audit-context-building|dimensional-analysis|differential-review|cargo-fuzz|aflpp|libafl|codeql|property-based-testing|modern-python|ui-ux-pro-max|bubbletea-code-review|jj-workflow|ralph-tui' "$CALL_LOG"; then
    echo 'retired skill was reinstalled' >&2
    exit 1
fi

: > "$CALL_LOG"
if FAIL_SKILL=swiftui-liquid-glass sh "$root/ai/skills/install-community.sh" > "$scratch/failure.out" 2> "$scratch/failure.err"; then
    echo 'installer swallowed failure' >&2
    exit 1
fi
grep -Fq 'upstream install diagnostic' "$scratch/failure.err"
grep -Fq 'Failed to install swiftui-liquid-glass' "$scratch/failure.err"
[ "$(wc -l < "$CALL_LOG" | tr -d ' ')" = 2 ]

# Exercise the real helper without running unrelated setup/configuration steps.
awk '/^install_claude_plugin\(\)/,/^}/' "$root/ai/setup.sh" > "$scratch/plugin-helper.sh"
cat >> "$scratch/plugin-helper.sh" <<'SH'
warn() { printf '%s\n' "$*" >&2; }
install_claude_plugin claude c-review@trailofbits 'requires workflow'
SH
: > "$CALL_LOG"
if sh "$scratch/plugin-helper.sh" > "$scratch/plugin.out" 2> "$scratch/plugin.err"; then
    echo 'plugin helper swallowed failure' >&2
    exit 1
fi
grep -Fqx -- 'plugin install c-review@trailofbits --scope user' "$CALL_LOG"
grep -Fq 'plugin install diagnostic' "$scratch/plugin.err"
grep -Fq 'requires workflow' "$scratch/plugin.err"

# Exercise profile selection and dependency ordering without running setup.
TEST_PROFILE_ROOT="$scratch/profiles"
export TEST_PROFILE_ROOT
mkdir -p "$TEST_PROFILE_ROOT/.claude" "$TEST_PROFILE_ROOT/.claude-team" \
    "$TEST_PROFILE_ROOT/.claude-ddb" \
    "$TEST_PROFILE_ROOT/.codex" "$TEST_PROFILE_ROOT/.codex-team"
cat > "$scratch/profile-loop.sh" <<'SH'
#!/bin/sh
set -eu
add_claude_marketplace() {
    printf 'marketplace %s %s\n' "$1" "$2" >> "$CALL_LOG"
    [ "$2" != "${FAIL_MARKETPLACE:-none}" ]
}
install_claude_plugin() {
    printf 'install %s %s %s\n' "$1" "$2" "$CLAUDE_CONFIG_DIR" >> "$CALL_LOG"
}
SH
# Substitute literal shell variables in the extracted fixture, not this process.
# shellcheck disable=SC2016
awk '/^# Install Claude Code plugin marketplaces/,/^# Setup MCP servers/ {print}' "$root/ai/setup.sh" |
    sed 's|\$HOME/\.\$variant|$TEST_PROFILE_ROOT/.$variant|g' >> "$scratch/profile-loop.sh"
: > "$CALL_LOG"
sh "$scratch/profile-loop.sh" > "$scratch/profile.out" 2> "$scratch/profile.err"
[ "$(grep -c '^install ' "$CALL_LOG")" = 36 ]
if grep -Eq '^install (codex|codex-team) ' "$CALL_LOG"; then
    echo 'plugin installed into an excluded host' >&2
    exit 1
fi
for profile in claude claude-team claude-ddb; do
    for plugin in code-improver c-review audit-context-building dimensional-analysis differential-review; do
        grep -Fqx "install $profile $plugin@trailofbits $TEST_PROFILE_ROOT/.$profile" "$CALL_LOG"
    done
done
: > "$CALL_LOG"
if FAIL_MARKETPLACE=claude-plugins-official sh "$scratch/profile-loop.sh" > "$scratch/prereq.out" 2> "$scratch/prereq.err"; then
    echo 'setup ignored required reviewer marketplace failure' >&2
    exit 1
fi
[ "$(wc -l < "$CALL_LOG" | tr -d ' ')" = 1 ]
printf '%s\n' 'PASS: pinned installs, retired targets, OpenTUI source, diagnostics, fail-fast, three-profile isolation and required reviewer failure'
