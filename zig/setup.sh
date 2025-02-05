#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒") $(gum style --bold "Setup Zig")"
zigup master --path-link /opt/homebrew/bin/zig
zigup fetch 0.13.0