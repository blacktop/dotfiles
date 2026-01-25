#!/bin/sh
# Install Gemini CLI extensions
set -o errexit -o nounset

installed_extensions=""
if [ -f "$HOME/.gemini/.extensions-installed" ]; then
  installed_extensions=$(cat "$HOME/.gemini/.extensions-installed")
fi

install_extension() {
  local url="$1"
  local repo="${url##*/}"
  local short="${repo%-extension}"
  if [ -n "$installed_extensions" ]; then
    if printf '%s\n' "$installed_extensions" | grep -Fq "$url"; then
      echo "$(gum style --faint "      ✓ $short (already installed)")"
      return 0
    fi
    if printf '%s\n' "$installed_extensions" | grep -Fq "$repo"; then
      echo "$(gum style --faint "      ✓ $short (already installed)")"
      return 0
    fi
    if [ "$short" != "$repo" ] && printf '%s\n' "$installed_extensions" | grep -Fq "$short"; then
      echo "$(gum style --faint "      ✓ $short (already installed)")"
      return 0
    fi
  fi
  echo "$(gum style --foreground "#BE05D0" "      +") $(gum style --bold "$short")"
  if ! gemini extensions install "$url"; then
    echo "$(gum style --foreground "#FF0000" "      ✗ Failed to install $short")"
  fi
}

install_extension https://github.com/galz10/pickle-rick-extension
install_extension https://github.com/gemini-cli-extensions/jules
install_extension https://github.com/upstash/context7
install_extension https://github.com/exa-labs/exa-mcp-server
install_extension https://github.com/gemini-cli-extensions/security
install_extension https://github.com/gemini-cli-extensions/code-review
