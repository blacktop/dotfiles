#!/bin/sh
set -eu

cd "$(dirname "$0")/.." || exit 1
script=tmux/scripts/agent-sessions.sh
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/agent-sessions.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT

mkdir -p "$test_dir/bin"
# shellcheck disable=SC2016 # These expressions belong to the generated mock.
printf '%s\n' \
    '#!/bin/sh' \
    'i=0' \
    'while [ "$i" -lt "${FAKE_AGENT_COUNT:-0}" ]; do' \
    '    printf "/opt/homebrew/bin/codex\\n"' \
    '    i=$((i + 1))' \
    'done' \
    'printf "/opt/homebrew/bin/mcp-tts\\n/usr/bin/rust-analyzer\\n"' \
    >"$test_dir/bin/ps"
chmod +x "$test_dir/bin/ps"

render() {
    env PATH="$test_dir/bin:/usr/bin:/bin" FAKE_AGENT_COUNT="$1" \
        "$script" 32 48
}

[ -z "$(render 31)" ] || {
    echo "FAIL: below-warning count rendered output" >&2
    exit 1
}

case "$(render 32)" in
*'#f6c177'*'⚠ 32 agents'*) ;;
*)
    echo "FAIL: warning threshold did not render warning state" >&2
    exit 1
    ;;
esac

case "$(render 47)" in
*'#f6c177'*'⚠ 47 agents'*) ;;
*)
    echo "FAIL: pre-alarm count did not remain warning state" >&2
    exit 1
    ;;
esac

case "$(render 48)" in
*'#eb6f92'*'⛔ 48 agents'*) ;;
*)
    echo "FAIL: alarm threshold did not render alarm state" >&2
    exit 1
    ;;
esac

if "$script" 48 32 >/dev/null 2>&1; then
    echo "FAIL: inverted thresholds were accepted" >&2
    exit 1
fi

echo "PASS: agent session status thresholds"
