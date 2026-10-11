#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Rust")"

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=privacy/env.sh
. "$script_dir/../privacy/env.sh"
# Homebrew ships rustup and its tool proxies, without rustup-init.
brew install rustup
rustup_prefix=$(brew --prefix rustup)
export PATH="$HOME/.cargo/bin:$rustup_prefix/bin:$PATH"
COMPLETIONS_DIR="$HOME/.config/fish/completions"

set -x
mkdir -p "$COMPLETIONS_DIR"
rustup default stable
rustup install nightly
rustup update
rustup completions fish >"$COMPLETIONS_DIR/rustup.fish"
rustup component add rust-src
rustup component add rustfmt clippy

# Use the official tap: the crates.io package named kache is unrelated.
brew install kunobi-ninja/kunobi/kache
# The login service keeps the daemon outside agent sandboxes; without it, a
# sandboxed kache command starts a daemon confined to that agent's sandbox.
kache init --yes

"$script_dir/install-cargo-cleaner.sh"
