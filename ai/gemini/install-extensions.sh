#!/bin/sh
# Install Gemini CLI extensions
set -o errexit -o nounset

install_extension() {
    url="$1"
    repo="${url##*/}"
    short="${repo%-extension}"
    if output=$(gemini extensions install "$url" 2>&1); then
        echo "$(gum style --foreground "#BE05D0" "      +") $(gum style --bold "$short")"
    elif printf '%s' "$output" | grep -qi 'already installed'; then
        echo "$(gum style --faint "      ✓ $short (already installed)")"
    else
        echo "$(gum style --foreground "#FF0000" "      ✗ Failed to install $short")"
        printf '        %s\n' "$output" | head -5
    fi
}

install_extension https://github.com/gemini-cli-extensions/ralph
install_extension https://github.com/gemini-cli-extensions/jules
install_extension https://github.com/upstash/context7
install_extension https://github.com/gemini-cli-extensions/security
install_extension https://github.com/gemini-cli-extensions/code-review
