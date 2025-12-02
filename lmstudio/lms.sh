#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒") $(gum style --bold "Setup LM Studio")"

brew install --cask lm-studio

# Check if LM Studio has been initialized
if [ ! -d "$HOME/.lmstudio" ] || [ ! -x "$HOME/.lmstudio/bin/lms" ]; then
    echo "$(gum style --bold --foreground "#BE05D0" "  -") Initializing LM Studio (first launch)..."

    # Launch LM Studio in background to initialize ~/.lmstudio
    open -a "LM Studio"

    # Wait for initialization (check for lms binary)
    max_wait=30
    count=0
    while [ ! -x "$HOME/.lmstudio/bin/lms" ] && [ $count -lt $max_wait ]; do
        sleep 1
        count=$((count + 1))
    done

    if [ ! -x "$HOME/.lmstudio/bin/lms" ]; then
        echo "$(gum style --bold --foreground "#FF0000" "  ✗") Failed to initialize LM Studio CLI"
        echo "Please launch LM Studio manually and try again"
        exit 1
    fi

    echo "$(gum style --bold --foreground "#00FF00" "  ✓") LM Studio initialized"
fi

echo "$(gum style --bold --foreground "#BE05D0" "  -") Download LM Studio Models..."
$HOME/.lmstudio/bin/lms get --yes openai/gpt-oss-20b
$HOME/.lmstudio/bin/lms get --yes qwen/qwen3-coder-30b
$HOME/.lmstudio/bin/lms get --yes mistralai/ministral-3-14b-reasoning
$HOME/.lmstudio/bin/lms get --yes google/gemma-3-27b
$HOME/.lmstudio/bin/lms get --yes bytedance/seed-oss-36b
