# Shared gum-styled output helpers for AI setup scripts.
# Source from POSIX sh: . "$(dirname "$0")/lib.sh"

msg() { echo "$(gum style --bold --foreground "#BE05D0" "  -") $1"; }
warn() { echo "$(gum style --bold --foreground "#FF9400" "  ⚠") $1"; }
ok() { echo "$(gum style --bold --foreground "#00C853" "  ✓") $1"; }
