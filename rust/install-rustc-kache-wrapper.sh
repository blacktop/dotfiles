#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
bin_dir=${RUSTC_KACHE_WRAPPER_BIN_DIR:-"$HOME/.local/bin"}
cargo_home=${CARGO_HOME:-"$HOME/.cargo"}
cargo_config=$cargo_home/config.toml
installed_wrapper=$bin_dir/rustc-kache-wrapper

if [ -f "$cargo_home/config" ] && [ ! -e "$cargo_config" ]; then
	cargo_config=$cargo_home/config
fi

mkdir -p "$bin_dir" "$cargo_home"
install -m 0755 "$script_dir/rustc-kache-wrapper.sh" "$installed_wrapper"

temporary_config=$(mktemp "$cargo_home/config.toml.XXXXXX")
trap 'rm -f "$temporary_config"' EXIT HUP INT TERM

if [ -f "$cargo_config" ]; then
	awk -v wrapper="$installed_wrapper" '
        function write_wrapper() {
            print "rustc-wrapper = \"" wrapper "\""
            wrapper_written = 1
        }

        BEGIN {
            in_build = 0
            saw_build = 0
            wrapper_written = 0
        }

        /^[[:space:]]*\[[^][]+\][[:space:]]*(#.*)?$/ {
            if (in_build && !wrapper_written) {
                write_wrapper()
            }

            in_build = ($0 ~ /^[[:space:]]*\[build\][[:space:]]*(#.*)?$/)
            if (in_build) {
                saw_build = 1
                wrapper_written = 0
            }

            print
            next
        }

        in_build && /^[[:space:]]*rustc-wrapper[[:space:]]*=/ {
            if (!wrapper_written) {
                write_wrapper()
            }
            next
        }

        { print }

        END {
            if (in_build && !wrapper_written) {
                write_wrapper()
            } else if (!saw_build) {
                if (NR > 0) {
                    print ""
                }
                print "[build]"
                write_wrapper()
            }
        }
    ' "$cargo_config" >"$temporary_config"
else
	printf '[build]\nrustc-wrapper = "%s"\n' "$installed_wrapper" >"$temporary_config"
fi

chmod 0600 "$temporary_config"

if [ -f "$cargo_config" ] && cmp -s "$cargo_config" "$temporary_config"; then
	rm -f "$temporary_config"
	trap - EXIT HUP INT TERM
	exit 0
fi

if [ -f "$cargo_config" ]; then
	backup=$cargo_config.rustc-wrapper-backup.$(date '+%Y%m%d-%H%M%S')-$$
	cp -p "$cargo_config" "$backup"
	printf 'Backed up Cargo config to %s\n' "$backup"
fi

if [ -L "$cargo_config" ]; then
	cp "$temporary_config" "$cargo_config"
	rm -f "$temporary_config"
else
	mv "$temporary_config" "$cargo_config"
fi
trap - EXIT HUP INT TERM
printf 'Configured Cargo to use %s\n' "$installed_wrapper"
