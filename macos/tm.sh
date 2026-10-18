#!/usr/bin/env bash

set -euo pipefail

if ((EUID == 0)); then
    echo "Run this script as your login user; it invokes sudo for tmutil." >&2
    exit 1
fi

exclude_path() {
    local path=$1
    echo "Time Machine: excluding ${path}..."
    /usr/bin/sudo /usr/bin/tmutil addexclusion -p "$path"
}

is_ignored_build_output() {
    local path=$1
    /usr/bin/git -C "${path%/*}" check-ignore -q -- "$path" 2>/dev/null
}

# Fixed-path exclusions survive deletion and recreation, and they can be
# registered before an optional tool creates its cache directory.
exclusions=(
    "${HOME}/.bun"
    "${HOME}/.cache"
    "${HOME}/.cargo"
    "${HOME}/.codeql"
    "${HOME}/.cursor"
    "${HOME}/.diffusionbee"
    "${HOME}/.gradle"
    "${HOME}/.lmstudio"
    "${HOME}/.npm"
    "${HOME}/.ollama"
    "${HOME}/.rustup"
    "${HOME}/.semgrep"
    "${HOME}/.swiftpm"
    "${HOME}/.tart"
    "${HOME}/.vscode"
    "${HOME}/Library/Caches"
    "${HOME}/Library/Developer/Xcode/DerivedData"
    "${HOME}/Library/Developer/Xcode/iOS DeviceSupport"
    "${HOME}/Library/pnpm/store"
    "${HOME}/go"
    "${APPLE_FIRMWARE_DIR:-${HOME}/Apple}"
    "${HOME}/Virtual Machines.localized"
    "${HOME}/.codex/worktrees"
    "${HOME}/.codex-team/worktrees"
    "${HOME}/.local/share/tmux-pm/worktrees"
    "${HOME}/Developer/Github"
    "${HOME}/Developer/SDKs"
    "${HOME}/RE"
    # Brewfile reproduces installed formulae and casks. Keep /opt/homebrew/etc
    # and /opt/homebrew/var backed up because they hold configuration and data.
    "/opt/homebrew/Cellar"
    "/opt/homebrew/Caskroom"
)

# Keep machine-specific paths out of the public repository. Entries are literal
# absolute or ~/ paths, one per line; blank lines and # comments are ignored.
local_exclusions="${HOME}/.config/time-machine-exclusions"
if [[ -f "$local_exclusions" ]]; then
    while IFS= read -r path || [[ -n "$path" ]]; do
        case "$path" in
        '' | \#*) continue ;;
        \~/*) path="${HOME}/${path#\~/}" ;;
        /*) ;;
        *)
            printf 'Time Machine: expected an absolute or ~/ path in %s\n' "$local_exclusions" >&2
            exit 1
            ;;
        esac
        exclusions+=("$path")
    done <"$local_exclusions"
fi

# tmutil requires root privileges for fixed-path exclusions. Authenticate once
# up front so the loop does not surprise the user with a delayed prompt.
/usr/bin/sudo -v

for path in "${exclusions[@]}"; do
    exclude_path "$path"
done

# tmutil stores paths, not name patterns. Find ignored, regenerable build output
# throughout Developer, including
# Rust, Swift, Zig, Gradle, Python, and JavaScript artifacts nested below
# organization and worktree folders. Agent worktrees under docs/.ai sit nine
# levels below Developer, hence the depth. Pruning keeps the scan out of
# repositories' metadata and large generated trees.
/usr/bin/find "${HOME}/Developer" -maxdepth 12 \
    \( -type d \( \
    -name .git -o \
    -name .jj -o \
    -path "${HOME}/Developer/Go" -o \
    -path "${HOME}/Developer/Github" -o \
    -path "${HOME}/Developer/SDKs" \
    \) -prune \) -o \
    \( -type d \( \
    -name .build -o \
    -name .gradle -o \
    -name .venv -o \
    -name .zig-cache -o \
    -name dist -o \
    -name node_modules -o \
    -name target -o \
    -name zig-cache \
    \) -print0 -prune \) |
    while IFS= read -r -d '' path; do
        is_ignored_build_output "$path" || continue
        exclude_path "$path"
    done
