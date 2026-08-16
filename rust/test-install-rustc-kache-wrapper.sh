#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/install-rustc-kache-wrapper-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

bin_dir=$test_root/bin
cargo_home=$test_root/cargo
cargo_config=$cargo_home/config.toml
installed_wrapper=$bin_dir/rustc-kache-wrapper

mkdir -p "$cargo_home"
cat >"$cargo_config" <<'EOF'
[net]
offline = true

[build]
jobs = 8
rustc-wrapper = "kache"

[term]
quiet = false
EOF

env \
	CARGO_HOME="$cargo_home" \
	RUSTC_KACHE_WRAPPER_BIN_DIR="$bin_dir" \
	"$script_dir/install-rustc-kache-wrapper.sh"

[ -x "$installed_wrapper" ]
grep -Fqx 'offline = true' "$cargo_config"
grep -Fqx 'jobs = 8' "$cargo_config"
grep -Fqx "rustc-wrapper = \"$installed_wrapper\"" "$cargo_config"
grep -Fqx 'quiet = false' "$cargo_config"

wrapper_count=$(grep -c '^[[:space:]]*rustc-wrapper[[:space:]]*=' "$cargo_config")
[ "$wrapper_count" -eq 1 ]

backup_count=$(find "$cargo_home" -type f -name 'config.toml.rustc-wrapper-backup.*' | wc -l | tr -d ' ')
[ "$backup_count" -eq 1 ]

env \
	CARGO_HOME="$cargo_home" \
	RUSTC_KACHE_WRAPPER_BIN_DIR="$bin_dir" \
	"$script_dir/install-rustc-kache-wrapper.sh"

new_backup_count=$(find "$cargo_home" -type f -name 'config.toml.rustc-wrapper-backup.*' | wc -l | tr -d ' ')
[ "$new_backup_count" -eq "$backup_count" ]

linked_cargo_home=$test_root/linked-cargo
linked_config=$test_root/linked-config.toml
mkdir -p "$linked_cargo_home"
printf '[build]\nrustc-wrapper = "kache"\n' >"$linked_config"
ln -s "$linked_config" "$linked_cargo_home/config.toml"

env \
	CARGO_HOME="$linked_cargo_home" \
	RUSTC_KACHE_WRAPPER_BIN_DIR="$bin_dir" \
	"$script_dir/install-rustc-kache-wrapper.sh"

[ -L "$linked_cargo_home/config.toml" ]
grep -Fqx "rustc-wrapper = \"$installed_wrapper\"" "$linked_config"

printf 'install-rustc-kache-wrapper tests passed\n'
