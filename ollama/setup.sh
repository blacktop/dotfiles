#!/bin/sh
set -o errexit -o nounset

# Start a ollama process
ollama serve &
PID=$!
# Ensure cleanup on exit
trap "kill $PID" EXIT

echo "$(gum style --bold --foreground "#BE05D0" "  -") Download Ollama Models..."
ollama pull gemma3:12b
ollama pull qwen3:14b
ollama pull devstral:24b
# ollama pull deepseek-r1:14b