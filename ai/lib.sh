# shellcheck shell=sh
# Shared gum-styled output helpers for AI setup scripts.
# Source from POSIX sh: . "$(dirname "$0")/lib.sh"

if ! command -v gum >/dev/null 2>&1; then
    echo "install gum first: brew install gum" >&2
    exit 1
fi

msg() { echo "$(gum style --bold --foreground "#BE05D0" "  -") $1"; }
warn() { echo "$(gum style --bold --foreground "#FF9400" "  ⚠") $1"; }
ok() { echo "$(gum style --bold --foreground "#00C853" "  ✓") $1"; }
