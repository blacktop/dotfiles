function brewu -d "Update All the things"
    brew update
    brew upgrade
    brew cleanup
    brew doctor
    brew cu -a

    # Helper function to update npm package and show version only if changed
    function __brewu_npm_update --argument-names pkg cmd
        if test -z "$cmd"
            set cmd (string split '/' $pkg)[-1]
        end

        # Get current version (empty if not installed)
        set -l old_version (command $cmd --version 2>/dev/null | string trim)

        # Check if update available using npm outdated
        set -l outdated (npm outdated -g $pkg 2>/dev/null)
        if test -n "$outdated"; or test -z "$old_version"
            npm i -g $pkg
            set -l new_version (command $cmd --version 2>/dev/null | string trim)
            if test "$old_version" != "$new_version"
                echo "  $cmd: $old_version → $new_version"
            end
        end
    end

    echo "Checking npm global packages..."
    __brewu_npm_update @openai/codex codex
    __brewu_npm_update @google/gemini-cli gemini
    __brewu_npm_update @anthropic-ai/claude-code claude
    __brewu_npm_update @github/copilot copilot
    __brewu_npm_update @mariozechner/pi-coding-agent pi

    functions -e __brewu_npm_update
end
