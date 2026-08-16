#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/rustc-kache-wrapper-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

mkdir -p "$test_root/bin" "$test_root/active"

cat >"$test_root/bin/kache" <<'EOF'
#!/bin/sh
set -eu

active_dir=$RUSTC_WRAPPER_TEST_ROOT/active
active=$active_dir/$$
mkdir "$active"
trap 'rmdir "$active"' EXIT

count=$(find "$active_dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
printf '%s\n' "$count" >>"$RUSTC_WRAPPER_TEST_ROOT/counts"

case "${RUSTC_WRAPPER_TEST_MODE:-normal}" in
fail)
	exit "${RUSTC_WRAPPER_TEST_EXIT_CODE:-1}"
	;;
signal)
	trap 'touch "$RUSTC_WRAPPER_TEST_ROOT/terminated"; exit 143' TERM
	touch "$RUSTC_WRAPPER_TEST_ROOT/ready"
	while :; do
		sleep 1
	done
	;;
*)
	sleep 1
	;;
esac
EOF
chmod 0755 "$test_root/bin/kache"

pids=
invocation=1
while [ "$invocation" -le 8 ]; do
	env \
		-u RUSTC_WRAPPER_SLOTS \
		PATH="$test_root/bin:$PATH" \
		TMPDIR="$test_root" \
		RUSTC_WRAPPER_TEST_ROOT="$test_root" \
		"$script_dir/rustc-kache-wrapper.sh" rustc --version &
	pids="$pids $!"
	invocation=$((invocation + 1))
done

for pid in $pids; do
	wait "$pid"
done

max_count=$(sort -nr "$test_root/counts" | sed -n '1p')
if [ "$max_count" != 4 ]; then
	printf 'expected exactly 4 concurrent kache processes, saw %s\n' "$max_count" >&2
	exit 1
fi

slot_root=$test_root/rustc-kache-wrapper-$(id -u)
ln -s "$$" "$slot_root/1"
env \
	PATH="$test_root/bin:$PATH" \
	TMPDIR="$test_root" \
	RUSTC_WRAPPER_SLOTS=1 \
	RUSTC_WRAPPER_TEST_ROOT="$test_root" \
	"$script_dir/rustc-kache-wrapper.sh" rustc --version &
queued_wrapper_pid=$!
sleep 0.1
kill -s TERM "$queued_wrapper_pid"
if wait "$queued_wrapper_pid"; then
	printf 'expected the queued wrapper to terminate\n' >&2
	exit 1
else
	exit_status=$?
fi

if [ "$exit_status" -ne 143 ] || [ "$(readlink "$slot_root/1")" != "$$" ]; then
	printf 'queued wrapper disturbed the active slot: status=%s\n' "$exit_status" >&2
	exit 1
fi
unlink "$slot_root/1"

sleep 0 &
stale_pid=$!
wait "$stale_pid"
ln -s "$stale_pid" "$slot_root/1"
env \
	PATH="$test_root/bin:$PATH" \
	TMPDIR="$test_root" \
	RUSTC_WRAPPER_SLOTS=1 \
	RUSTC_WRAPPER_TEST_ROOT="$test_root" \
	"$script_dir/rustc-kache-wrapper.sh" rustc --version

if env \
	PATH="$test_root/bin:$PATH" \
	TMPDIR="$test_root" \
	RUSTC_WRAPPER_SLOTS=0 \
	RUSTC_WRAPPER_TEST_ROOT="$test_root" \
	"$script_dir/rustc-kache-wrapper.sh" rustc --version 2>/dev/null; then
	printf 'expected a zero slot count to fail\n' >&2
	exit 1
fi

if env \
	PATH="$test_root/bin:$PATH" \
	TMPDIR="$test_root" \
	RUSTC_WRAPPER_SLOTS=1 \
	RUSTC_WRAPPER_TEST_ROOT="$test_root" \
	RUSTC_WRAPPER_TEST_MODE=fail \
	RUSTC_WRAPPER_TEST_EXIT_CODE=42 \
	"$script_dir/rustc-kache-wrapper.sh" rustc --version; then
	printf 'expected kache failure to propagate\n' >&2
	exit 1
else
	exit_status=$?
fi

if [ "$exit_status" -ne 42 ]; then
	printf 'expected kache exit status 42, saw %s\n' "$exit_status" >&2
	exit 1
fi

env \
	PATH="$test_root/bin:$PATH" \
	TMPDIR="$test_root" \
	RUSTC_WRAPPER_SLOTS=1 \
	RUSTC_WRAPPER_TEST_ROOT="$test_root" \
	RUSTC_WRAPPER_TEST_MODE=signal \
	"$script_dir/rustc-kache-wrapper.sh" rustc --version &
wrapper_pid=$!

ready_attempt=0
while [ ! -f "$test_root/ready" ] && [ "$ready_attempt" -lt 50 ]; do
	sleep 0.1
	ready_attempt=$((ready_attempt + 1))
done

if [ ! -f "$test_root/ready" ]; then
	printf 'timed out waiting for the fake kache process\n' >&2
	kill -s TERM "$wrapper_pid" 2>/dev/null || true
	wait "$wrapper_pid" 2>/dev/null || true
	exit 1
fi

kill -s TERM "$wrapper_pid"
if wait "$wrapper_pid"; then
	printf 'expected the terminated wrapper to fail\n' >&2
	exit 1
else
	exit_status=$?
fi

if [ "$exit_status" -ne 143 ] || [ ! -f "$test_root/terminated" ]; then
	printf 'wrapper did not forward SIGTERM cleanly: status=%s\n' "$exit_status" >&2
	exit 1
fi

if [ -e "$slot_root/1" ] || [ -L "$slot_root/1" ]; then
	printf 'wrapper left its slot behind after SIGTERM\n' >&2
	exit 1
fi

printf 'rustc-kache-wrapper tests passed\n'
