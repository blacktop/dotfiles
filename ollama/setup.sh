#!/bin/sh
set -o errexit -o nounset

# Start a ollama process
ollama serve &
PID=$!
# Ensure cleanup on exit
trap "kill $PID" EXIT

echo "$(gum style --bold --foreground "#BE05D0" "  -") Download Ollama Models..."
ollama pull deepseek-r1:14b
ollama pull llama3.2-vision:latest
ollama pull llama3.2:latest
ollama pull mistral-small:24b
# ollama run codellama:13b