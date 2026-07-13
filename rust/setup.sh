#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Rust")"

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
export PATH="$HOME/.cargo/bin:$PATH"
COMPLETIONS_DIR="$HOME/.config/fish/completions"

if ! command -v rustc >/dev/null; then
    rustup-init -y # rustup-init was installed by Homebrew
fi

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
kache init --yes --no-service

"$script_dir/install-cargo-cleaner.sh"
