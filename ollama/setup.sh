#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒") $(gum style --bold "Setup Ollama")"
brew install --cask ollama

# Start a ollama process
ollama serve &
PID=$!
# Ensure cleanup on exit
trap "kill $PID" EXIT

echo "$(gum style --bold --foreground "#BE05D0" "  -") Download Ollama Models..."
ollama pull gpt-oss:20b
ollama pull qwen3-coder:30b
ollama pull gemma3:12b
ollama pull bytedance/seed-oss-36b
