#!/bin/sh
set -eu

# Limit concurrent kache/rustc wrapper work across Cargo processes sharing this
# runtime directory.
slot_count=${RUSTC_WRAPPER_SLOTS:-4}
case "$slot_count" in
'' | *[!0-9]* | 0)
	printf 'rustc-kache-wrapper: RUSTC_WRAPPER_SLOTS must be a positive integer\n' >&2
	exit 2
	;;
esac

umask 077
slot_root=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/rustc-kache-wrapper-$(id -u)
mkdir -p "$slot_root"
chmod 0700 "$slot_root"

slot=
slot_owner=
kache_pid=
pending_signal=
signal_status=0

# Called by the EXIT trap.
# shellcheck disable=SC2329
release_slot() {
	[ -n "$slot" ] || return 0

	owner=$(readlink "$slot" 2>/dev/null || true)
	if [ "$owner" = "$slot_owner" ]; then
		unlink "$slot" 2>/dev/null || true
	fi
}

# Called by the signal traps.
# shellcheck disable=SC2329
handle_signal() {
	pending_signal=$1
	signal_status=$2

	if [ -n "$kache_pid" ]; then
		kill -s "$pending_signal" "$kache_pid" 2>/dev/null || true
	fi
}

trap release_slot 0
trap 'handle_signal HUP 129' HUP
trap 'handle_signal INT 130' INT
trap 'handle_signal QUIT 131' QUIT
trap 'handle_signal TERM 143' TERM

while [ -z "$slot" ]; do
	if [ "$signal_status" -ne 0 ]; then
		exit "$signal_status"
	fi

	slot_number=1
	while [ "$slot_number" -le "$slot_count" ]; do
		candidate=$slot_root/$slot_number
		if ln -s "$$" "$candidate" 2>/dev/null; then
			slot=$candidate
			slot_owner=$$
			break
		fi

		owner=$(readlink "$candidate" 2>/dev/null || true)
		case "$owner" in
		'' | *[!0-9]*)
			owner_is_stale=1
			;;
		*)
			if kill -0 "$owner" 2>/dev/null; then
				owner_is_stale=0
			else
				owner_is_stale=1
			fi
			;;
		esac

		if [ "$owner_is_stale" -eq 1 ]; then
			current_owner=$(readlink "$candidate" 2>/dev/null || true)
			if [ "$current_owner" = "$owner" ]; then
				unlink "$candidate" 2>/dev/null || true
			fi
		fi

		slot_number=$((slot_number + 1))
	done

	[ -n "$slot" ] || sleep 1
done

if [ "$signal_status" -ne 0 ]; then
	exit "$signal_status"
fi

if ! command -v kache >/dev/null 2>&1; then
	printf 'rustc-kache-wrapper: kache was not found in PATH\n' >&2
	exit 127
fi

(
	trap - HUP INT QUIT TERM
	exec kache "$@"
) &
kache_pid=$!
if [ -n "$pending_signal" ]; then
	kill -s "$pending_signal" "$kache_pid" 2>/dev/null || true
fi

replacement=$slot_root/.owner-$$
if ! ln -s "$kache_pid" "$replacement" 2>/dev/null ||
	! mv -f "$replacement" "$slot"; then
	unlink "$replacement" 2>/dev/null || true
	kill -s TERM "$kache_pid" 2>/dev/null || true
	wait "$kache_pid" 2>/dev/null || true
	printf 'rustc-kache-wrapper: failed to transfer slot ownership to kache\n' >&2
	exit 1
fi
slot_owner=$kache_pid

while :; do
	if wait "$kache_pid"; then
		kache_status=0
	else
		kache_status=$?
	fi

	if ! kill -0 "$kache_pid" 2>/dev/null; then
		break
	fi
done

if [ "$signal_status" -ne 0 ]; then
	exit "$signal_status"
fi
exit "$kache_status"
