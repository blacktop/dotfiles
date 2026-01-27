#!/bin/sh
# Install community skills via npx skills add
set -o errexit -o nounset

install_skill() {
  local repo="$1"
  local skill="${2:-}"
  local name="${skill:-$(basename "$repo")}"
  echo "$(gum style --foreground "#BE05D0" "      +") $(gum style --bold "$name")"
  # Install to all agent skill directories
  if ! npx -y add-skill "$repo" ${skill:+--skill "$skill"} -g -y -a claude-code -a codex -a gemini-cli 2>/dev/null; then
    echo "$(gum style --foreground "#FF0000" "      ✗ Failed to install $name")"
  fi
}

# Business
install_skill https://github.com/coreyhaines31/marketingskills
# UI/UX
install_skill https://github.com/nextlevelbuilder/ui-ux-pro-max-skill ui-ux-pro-max
# Swift
install_skill https://github.com/dimillian/skills swiftui-ui-patterns
install_skill https://github.com/dimillian/skills swiftui-liquid-glass
install_skill https://github.com/dimillian/skills swiftui-performance-audit
install_skill https://github.com/dimillian/skills swiftui-view-refactor
install_skill https://github.com/dimillian/skills swift-concurrency-expert
install_skill https://github.com/avdlee/swiftui-agent-skill swiftui-expert-skill
install_skill https://github.com/avdlee/swift-concurrency-agent-skill swift-concurrency
install_skill https://github.com/jeffallan/claude-skills swift-expert
install_skill https://github.com/jamesrochabrun/skills swiftui-animation
install_skill https://github.com/existential-birds/beagle swiftui-code-review
install_skill https://github.com/wshobson/agents mobile-ios-design
# Productivity
install_skill https://github.com/subsy/ralph-tui
install_skill https://github.com/clawdbot/clawdbot things-mac
install_skill https://github.com/trevors/dot-claude jj-workflow
# CLI/TUI
install_skill https://github.com/jeffallan/claude-skills cli-developer
install_skill https://github.com/steipete/agent-scripts create-cli
install_skill https://github.com/rand/cc-polymath discover-tui
install_skill https://github.com/msmps/opentui-skill opentui
install_skill https://github.com/existential-birds/beagle bubbletea-code-review
# ToB
install_skill https://github.com/trailofbits/skills
# Mine
install_skill https://github.com/blacktop/ipsw-skill ipsw
install_skill https://github.com/blacktop/mcp-tts speak
