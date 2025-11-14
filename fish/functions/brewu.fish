function brewu -d "Update All the things"
  brew update
  brew upgrade
  brew cleanup
  brew doctor
  brew cu -a
  npm i -g @openai/codex @google/gemini-cli @anthropic-ai/claude-code @fission-ai/openspec @github/copilot
end
