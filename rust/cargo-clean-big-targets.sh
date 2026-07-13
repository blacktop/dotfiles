#!/bin/sh
set -eu

usage() {
    printf '%s\n' \
        'Usage: cargo-clean-big-targets [--dry-run] [--root PATH]' \
        '                               [--min-mib N] [--inactive-days N]' \
        '' \
        'Clean conventional Rust target directories that are both large and inactive.'
}

log() {
    printf '%s %s\n' "$(/bin/date '+%Y-%m-%dT%H:%M:%S%z')" "$*"
}

die() {
    log "ERROR: $*" >&2
    exit 1
}

is_positive_integer() {
    case "$1" in
    '' | *[!0-9]*) return 1 ;;
    esac
    [ "$1" -gt 0 ]
}

dry_run=0
scan_root=${CARGO_CLEAN_ROOT:-"$HOME/Developer"}
min_mib=${CARGO_CLEAN_MIN_MIB:-10240}
inactive_days=${CARGO_CLEAN_INACTIVE_DAYS:-14}

while [ "$#" -gt 0 ]; do
    case "$1" in
    --dry-run)
        dry_run=1
        shift
        ;;
    --root)
        [ "$#" -ge 2 ] || die '--root requires a path'
        scan_root=$2
        shift 2
        ;;
    --min-mib)
        [ "$#" -ge 2 ] || die '--min-mib requires a positive integer'
        min_mib=$2
        shift 2
        ;;
    --inactive-days)
        [ "$#" -ge 2 ] || die '--inactive-days requires a positive integer'
        inactive_days=$2
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        die "unknown argument: $1"
        ;;
    esac
done

is_positive_integer "$min_mib" || die 'minimum size must be a positive integer in MiB'
is_positive_integer "$inactive_days" || die 'inactive days must be a positive integer'

case "$scan_root" in
/*) ;;
*) die 'scan root must be an absolute path' ;;
esac

if [ ! -d "$scan_root" ]; then
    log "Scan root does not exist; nothing to do: $scan_root"
    exit 0
fi

cargo_bin=${CARGO_CLEAN_CARGO_BIN:-"$HOME/.cargo/bin/cargo"}
if [ ! -x "$cargo_bin" ]; then
    cargo_bin=$(command -v cargo || true)
fi
[ -n "$cargo_bin" ] || die 'cargo was not found'

threshold_kib=$((min_mib * 1024))
candidates=$(/usr/bin/mktemp -t cargo-clean-targets)
metadata=$(/usr/bin/mktemp -t cargo-clean-metadata)
trap '/bin/rm -f "$candidates" "$metadata"' EXIT HUP INT TERM

if ! /usr/bin/find "$scan_root" \
    \( -type d \( -name .git -o -name .jj -o -name .direnv -o -name node_modules -o -name vendor \) -prune \) -o \
    \( -type d -name target -print -prune \) >"$candidates"; then
    die "failed to scan: $scan_root"
fi

scanned=0
oversized=0
eligible=0
eligible_kib=0
cleaned=0
reclaimed_kib=0
failures=0

while IFS= read -r target; do
    [ -n "$target" ] || continue
    scanned=$((scanned + 1))

    project_dir=${target%/target}
    manifest=$project_dir/Cargo.toml
    [ -f "$manifest" ] || continue

    size_kib=$(/usr/bin/du -sk "$target" 2>/dev/null | /usr/bin/awk 'NR == 1 { print $1 }')
    case "$size_kib" in
    '' | *[!0-9]*)
        log "WARN: could not measure $target"
        continue
        ;;
    esac

    [ "$size_kib" -ge "$threshold_kib" ] || continue
    oversized=$((oversized + 1))

    if /usr/bin/find "$target" -type f -mtime "-$inactive_days" -print -quit 2>/dev/null | /usr/bin/grep -q .; then
        log "SKIP recent target: $target (${size_kib} KiB)"
        continue
    fi

    clean_mode=explicit_target
    cache_tag=$target/CACHEDIR.TAG
    if [ ! -f "$cache_tag" ] ||
        ! /usr/bin/grep -q '^Signature: 8a477f597d28d172789f06886806bc55$' "$cache_tag"; then
        if ! "$cargo_bin" metadata \
            --format-version 1 \
            --no-deps \
            --offline \
            --locked \
            --manifest-path "$manifest" >"$metadata"; then
            log "SKIP target Cargo could not validate: $target"
            continue
        fi

        resolved_target=$(/usr/bin/plutil -extract target_directory raw -o - "$metadata" 2>/dev/null || true)
        if [ "$resolved_target" != "$target" ]; then
            log "SKIP target mismatch: found=$target cargo=$resolved_target"
            continue
        fi
        clean_mode=manifest_target
    fi

    eligible=$((eligible + 1))
    eligible_kib=$((eligible_kib + size_kib))

    if [ "$dry_run" -eq 1 ]; then
        log "DRY-RUN clean: $target (${size_kib} KiB)"
        continue
    fi

    log "CLEAN: $target (${size_kib} KiB)"
    clean_succeeded=0
    if [ "$clean_mode" = explicit_target ]; then
        if "$cargo_bin" clean \
            --offline \
            --color never \
            --manifest-path "$manifest" \
            --target-dir "$target"; then
            clean_succeeded=1
        fi
    elif "$cargo_bin" clean \
        --offline \
        --color never \
        --manifest-path "$manifest"; then
        clean_succeeded=1
    fi

    if [ "$clean_succeeded" -eq 1 ]; then
        cleaned=$((cleaned + 1))
        reclaimed_kib=$((reclaimed_kib + size_kib))
    else
        log "ERROR: cargo clean failed for $manifest" >&2
        failures=$((failures + 1))
    fi
done <"$candidates"

log "Finished: scanned=$scanned oversized=$oversized eligible=$eligible eligible_mib=$((eligible_kib / 1024)) cleaned=$cleaned reclaimed_mib=$((reclaimed_kib / 1024)) failures=$failures dry_run=$dry_run"
[ "$failures" -eq 0 ]
