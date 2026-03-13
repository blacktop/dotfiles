#!/bin/sh
# Install community skills to ~/.agents/skills (unified location for all AI agents)
set -o errexit -o nounset

install_skill() {
  repo="$1"
  skill="${2:-}"
  name="${skill:-$(basename "$repo")}"
  echo "$(gum style --foreground "#BE05D0" "      +") $(gum style --bold "$name")"
  # Install to ~/.agents/skills via --agent amp -g (global/user scope)
  if ! npx -y skills add "$repo" ${skill:+--skill "$skill"} --agent amp -g -y 2>/dev/null; then
    echo "$(gum style --foreground "#FF0000" "      ✗ Failed to install $name")"
  fi
}

# Business
# install_skill https://github.com/coreyhaines31/marketingskills
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
# install_skill https://github.com/clawdbot/clawdbot things-mac
install_skill https://github.com/trevors/dot-claude jj-workflow
# CLI/TUI
install_skill https://github.com/jeffallan/claude-skills cli-developer
install_skill https://github.com/steipete/agent-scripts create-cli
install_skill https://github.com/rand/cc-polymath discover-tui
install_skill https://github.com/msmps/opentui-skill opentui
install_skill https://github.com/existential-birds/beagle bubbletea-code-review
# ToB
# install_skill https://github.com/trailofbits/skills
install_skill https://github.com/trailofbits/skills ask-questions-if-underspecified
install_skill https://github.com/trailofbits/skills codeql
install_skill https://github.com/trailofbits/skills audit-context-building
install_skill https://github.com/trailofbits/skills property-based-testing
install_skill https://github.com/trailofbits/skills variant-analysis
install_skill https://github.com/trailofbits/skills modern-python
install_skill https://github.com/trailofbits/skills semgrep-rule-creator
install_skill https://github.com/trailofbits/skills cargo-fuzz
install_skill https://github.com/trailofbits/skills libfuzzer
install_skill https://github.com/trailofbits/skills ossfuzz
install_skill https://github.com/trailofbits/skills aflpp
install_skill https://github.com/trailofbits/skills libafl
install_skill https://github.com/trailofbits/skills fuzzing-dictionary
install_skill https://github.com/trailofbits/skills constant-time-testing
# Rust
install_skill https://github.com/apollographql/skills rust-best-practices
install_skill https://github.com/jeffallan/claude-skills rust-engineer
# Mine
install_skill https://github.com/blacktop/ipsw-skill ipsw
install_skill https://github.com/blacktop/mcp-tts speak
