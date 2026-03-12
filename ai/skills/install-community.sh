#!/bin/sh
# Install community skills to ~/.agents/skills (unified location for all AI agents)
set -o errexit -o nounset

install_skill() {
  repo="$1"
  skill="${2:-}"
  name="${skill:-$(basename "$repo")}"
  echo "$(gum style --foreground "#BE05D0" "      +") $(gum style --bold "$name")"
  # Install to ~/.agents/skills via --agent amp -g (global/user scope)
  if ! npx -y add-skill "$repo" ${skill:+--skill "$skill"} --agent amp -g -y 2>/dev/null; then
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
npx skills add https://github.com/trailofbits/skills --skill ask-questions-if-underspecified
npx skills add https://github.com/trailofbits/skills --skill codeql
npx skills add https://github.com/trailofbits/skills --skill audit-context-building
npx skills add https://github.com/trailofbits/skills --skill property-based-testing
npx skills add https://github.com/trailofbits/skills --skill variant-analysis
npx skills add https://github.com/trailofbits/skills --skill modern-python
npx skills add https://github.com/trailofbits/skills --skill semgrep-rule-creator
npx skills add https://github.com/trailofbits/skills --skill cargo-fuzz
npx skills add https://github.com/trailofbits/skills --skill libfuzzer
npx skills add https://github.com/trailofbits/skills --skill ossfuzz
npx skills add https://github.com/trailofbits/skills --skill aflpp
npx skills add https://github.com/trailofbits/skills --skill libafl
npx skills add https://github.com/trailofbits/skills --skill fuzzing-dictionary
npx skills add https://github.com/trailofbits/skills --skill constant-time-testing
# Rust
install_skill https://github.com/apollographql/skills rust-best-practices
install_skill https://github.com/jeffallan/claude-skills rust-engineer
# Mine
install_skill https://github.com/blacktop/ipsw-skill ipsw
install_skill https://github.com/blacktop/mcp-tts speak
