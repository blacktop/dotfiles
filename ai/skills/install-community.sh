#!/bin/sh
# Install community skills to ~/.agents/skills (unified location for all AI agents)
set -o errexit -o nounset

readonly SKILLS_CLI_VERSION=1.7.0

# Opt out explicitly even when run outside a configured agent session.
export DISABLE_TELEMETRY=1
export DO_NOT_TRACK=1

install_skill() {
    repo="$1"
    skill="${2:-}"
    name="${skill:-$(basename "$repo")}"
    printf "%s %s\n" "$(gum style --foreground "#BE05D0" "      +")" "$(gum style --bold "$name")"
    # Install to ~/.agents/skills via --agent amp -g (global/user scope)
    if [ -n "$skill" ]; then
        set -- --skill "$skill"
    else
        set --
    fi
    if ! npx -y "skills@$SKILLS_CLI_VERSION" add "$repo" "$@" --agent amp -g -y; then
        printf "%s\n" "$(gum style --foreground "#FF0000" "      ✗ Failed to install $name")" >&2
        return 1
    fi
}

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
# Design
# Keep the portable default for Codex; Claude also exposes its official plugin.
install_skill https://github.com/anthropics/skills frontend-design
install_skill https://github.com/leonxlnx/taste-skill
# Productivity
install_skill https://github.com/ayghri/i-have-adhd i-have-adhd
# CLI/TUI
install_skill https://github.com/ast-grep/claude-skill ast-grep
install_skill https://github.com/jeffallan/claude-skills cli-developer
install_skill https://github.com/steipete/agent-scripts create-cli
install_skill https://github.com/anomalyco/opentui opentui
# Portable ToB skills. Workflow/agent-backed plugins belong in Claude's plugin
# cache (ai/setup.sh), not this directory shared with Codex.
install_skill https://github.com/trailofbits/skills variant-analysis
install_skill https://github.com/trailofbits/skills semgrep-rule-creator
install_skill https://github.com/trailofbits/skills libfuzzer
install_skill https://github.com/trailofbits/skills ossfuzz
install_skill https://github.com/trailofbits/skills fuzzing-dictionary
install_skill https://github.com/trailofbits/skills constant-time-testing
# ToB Curated
install_skill https://github.com/trailofbits/skills-curated skill-extractor
# Rust
install_skill https://github.com/apollographql/skills rust-best-practices
install_skill https://github.com/jeffallan/claude-skills rust-engineer
# Mine
install_skill https://github.com/blacktop/ipsw-skill ipsw
install_skill https://github.com/blacktop/mcp-tts speak
