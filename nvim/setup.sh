#!/bin/sh
set -o errexit -o nounset

# NOTE: http://www.lazyvim.org

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Neovim")"

echo "$(gum style --bold --foreground "#BE05D0" "  -") Setup neovim config..."

NVIM_DIR="$(cd "$(dirname "$0")" && pwd)"
NVIM_CONFIG="$HOME/.config/nvim"

# Back up existing config if it's not already our symlink or our files
if [ -d "$NVIM_CONFIG" ] && [ ! -L "$NVIM_CONFIG/init.lua" ]; then
    mv "$NVIM_CONFIG" "${NVIM_CONFIG}.bak.$(date +%s)" || true
fi

mkdir -p "$NVIM_CONFIG"
mkdir -p "$NVIM_CONFIG/lua/config"
mkdir -p "$NVIM_CONFIG/lua/plugins"
mkdir -p "$NVIM_CONFIG/after/ftplugin"
mkdir -p "$NVIM_CONFIG/after/queries/go"

# Symlink top-level files
for f in init.lua stylua.toml; do
    [ -f "$NVIM_DIR/$f" ] && ln -sf "$NVIM_DIR/$f" "$NVIM_CONFIG/$f"
done

# Symlink config modules
for f in "$NVIM_DIR"/lua/config/*.lua; do
    ln -sf "$f" "$NVIM_CONFIG/lua/config/$(basename "$f")"
done

# Symlink plugin specs
for f in "$NVIM_DIR"/lua/plugins/*.lua; do
    ln -sf "$f" "$NVIM_CONFIG/lua/plugins/$(basename "$f")"
done

# Symlink ftplugin files
for f in "$NVIM_DIR"/after/ftplugin/*.lua; do
    ln -sf "$f" "$NVIM_CONFIG/after/ftplugin/$(basename "$f")"
done

# Symlink treesitter queries
for f in "$NVIM_DIR"/after/queries/go/*.scm; do
    [ -f "$f" ] && ln -sf "$f" "$NVIM_CONFIG/after/queries/go/$(basename "$f")"
done

echo "$(gum style --bold --foreground "#BE05D0" "  -") Update neovim plugins..."
nvim --headless "+Lazy! sync" +qa
