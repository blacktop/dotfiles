#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒") $(gum style --bold "Setup LM Studio")"

brew install --cask lm-studio

echo "$(gum style --bold --foreground "#BE05D0" "  -") eDownload LM Studio Models..."
lms get --yes --mlx openai/gpt-oss-20b
lms get --yes --mlx qwen/qwen3-coder-30b
lms get --yes --mlx gemma3:12b
lms get --yes --mlx bytedance/seed-oss-36b
