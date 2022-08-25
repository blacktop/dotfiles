#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Rust")"

export PATH="$HOME/.cargo/bin:$PATH"
COMPLETIONS_DIR="$HOME/.config/fish/completions"

if ! command -v rustup >/dev/null; then
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