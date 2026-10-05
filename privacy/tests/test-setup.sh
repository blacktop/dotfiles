#!/bin/sh
set -eu
# shellcheck source=ai/tests/lib.sh
. "$(dirname "$0")/../../ai/tests/lib.sh"
mkdir -p "$scratch/bin" "$scratch/profiles"
cat >"$scratch/bin/go" <<'SH'
#!/bin/sh
set -eu
[ "$DO_NOT_TRACK" = 1 ] && [ "$DISABLE_TELEMETRY" = 1 ]
[ "$DISABLE_ERROR_REPORTING" = 1 ] && [ "$HOMEBREW_NO_ANALYTICS" = 1 ]
[ "$SEMGREP_SEND_METRICS" = off ] && [ "$KACHE_RECORD_SESSIONS" = 0 ]
case "$*" in
'telemetry off') printf 'go off\n' >>"$TEST_PRIVACY_LOG" ;;
telemetry) printf '%s\n' "${TEST_PRIVACY_MODE:-off}" ;;
*) exit 91 ;;
esac
SH
cat >"$scratch/bin/brew" <<'SH'
#!/bin/sh
set -eu
[ "$HOMEBREW_NO_ANALYTICS" = 1 ]
[ "$*" = 'analytics off' ]
printf 'brew off\n' >>"$TEST_PRIVACY_LOG"
SH
chmod +x "$scratch/bin/go" "$scratch/bin/brew"
run_setup() {
	PATH="$scratch/bin:/usr/bin:/bin" TEST_PRIVACY_LOG="$scratch/calls" \
		sh "$root/privacy/setup.sh" "$scratch/profiles"
}
run_setup >"$scratch/result"
printf 'go off\nbrew off\n' >"$scratch/expected"
cmp "$scratch/calls" "$scratch/expected"
target="$scratch/profiles/.config/fish/conf.d/00-privacy.fish"
[ -L "$target" ]
cmp "$target" "$root/fish/conf.d/00-privacy.fish"
run_setup >/dev/null
# A failed Go verification must stop before other host settings are changed.
: >"$scratch/calls"
if TEST_PRIVACY_MODE=local run_setup >"$scratch/fail.out" 2>"$scratch/fail.err"; then
	echo 'Expected Go verification to fail' >&2
	exit 1
fi
printf 'go off\n' >"$scratch/expected"
cmp "$scratch/calls" "$scratch/expected"
# Preserve an existing user-owned file instead of silently overwriting it.
unlink "$target"
printf 'user-owned\n' >"$target"
if run_setup >"$scratch/conflict.out" 2>"$scratch/conflict.err"; then
	echo 'Expected existing-file conflict' >&2
	exit 1
fi
grep -qx 'user-owned' "$target"
printf 'PASS: opt-outs precede commands, Go off verification, persistent Homebrew opt-out, Fish installation, rerun, existing-file preservation\n'
