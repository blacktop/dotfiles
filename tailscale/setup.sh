#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: ./tailscale/setup.sh [--profile server|desktop|skip] [--no-login]

Profiles:
  server   Homebrew system daemon; recommended for a headless Mac mini
  desktop  Standalone Mac app with automatic updates
  skip     Leave Tailscale unchanged

With no profile, gum prompts in a terminal. Unattended runs skip Tailscale
unless SETUP_TAILSCALE_PROFILE is set. --no-login installs the selected
variant without opening the app or starting an interactive login.
USAGE
}

info() {
    printf '[tailscale] %s\n' "$*" >&2
}

has_terminal() {
    [[ -t 0 && -t 1 ]]
}

installed_gui_kind() {
    local app bundle_id kind=""
    for app in /Applications/Tailscale.app "$HOME/Applications/Tailscale.app"; do
        [[ -d "$app" ]] || continue
        bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null || true)
        if [[ "$bundle_id" != io.tailscale.ipn.macsys ]]; then
            printf '%s\n' 'app-store-or-unknown'
            return 0
        fi
        kind=standalone
    done
    [[ -n "$kind" ]] || return 1
    printf '%s\n' "$kind"
}

has_manual_daemon() {
    [[ -e /Library/LaunchDaemons/com.tailscale.tailscaled.plist ]]
}

main() {
    local profile="${SETUP_TAILSCALE_PROFILE:-}" login=true
    local brew_bin script_dir gui_kind formula_installed=false tailscale_prefix
    local installed_formulae installed_casks
    script_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --profile)
            [[ $# -ge 2 ]] || {
                usage >&2
                return 2
            }
            profile="$2"
            shift 2
            ;;
        --no-login)
            login=false
            shift
            ;;
        -h | --help)
            usage
            return 0
            ;;
        *)
            info "Unknown option: $1"
            usage >&2
            return 2
            ;;
        esac
    done

    case "$profile" in
    "" | server | desktop | skip) ;;
    *)
        info "Unknown profile '$profile'; choose server, desktop, or skip."
        return 2
        ;;
    esac
    if [[ "$profile" == skip ]] || { [[ -z "$profile" ]] && ! has_terminal; }; then
        info 'Skipped. Set SETUP_TAILSCALE_PROFILE=server or desktop to opt in.'
        return 0
    fi

    [[ "$(uname -s)" == Darwin ]] || {
        info 'This installer requires macOS.'
        return 1
    }
    brew_bin=$(command -v brew) || {
        info 'Install Homebrew first, then rerun this script.'
        return 1
    }
    # shellcheck source=privacy/env.sh
    . "$script_dir/../privacy/env.sh"

    if [[ -z "$profile" ]]; then
        if ! command -v gum >/dev/null 2>&1; then
            "$brew_bin" install gum
        fi
        profile=$(gum choose --header 'Choose a Tailscale profile' --label-delimiter '|' \
            'Server: start before login (recommended for a headless mini)|server' \
            'Desktop: standalone Mac app and automatic updates|desktop' \
            'Skip Tailscale|skip') || return $?
        [[ "$profile" != skip ]] || {
            info 'Skipped.'
            return 0
        }
        case "$profile" in
        server | desktop) ;;
        *)
            info 'No valid profile selected.'
            return 1
            ;;
        esac
    fi

    gui_kind=$(installed_gui_kind || true)
    installed_formulae=$("$brew_bin" list --formula -1) || return $?
    if grep -Fxq tailscale <<<"$installed_formulae"; then
        formula_installed=true
    fi
    if has_manual_daemon || { [[ "$formula_installed" == false ]] && command -v tailscaled >/dev/null 2>&1; }; then
        info 'Found a manually installed tailscaled. Stop and remove that installation before changing its manager.'
        return 1
    fi

    case "$profile" in
    desktop)
        if [[ "$formula_installed" == true ]]; then
            info 'The Homebrew daemon is installed. Keep it, or explicitly stop and uninstall it before choosing desktop.'
            return 1
        fi
        if [[ -n "$gui_kind" && "$gui_kind" != standalone ]]; then
            info 'A different Tailscale app is installed. Follow the macOS variant-switching instructions before continuing: https://tailscale.com/docs/concepts/macos-variants'
            return 1
        fi
        if [[ "$gui_kind" == standalone ]]; then
            info 'The standalone Mac app is already installed.'
        else
            "$brew_bin" install --cask tailscale-app
        fi
        if [[ "$login" == true ]] && has_terminal; then
            open -a Tailscale
        fi
        info 'Open Tailscale to approve its network extension, sign in, and enable automatic updates.'
        ;;
    server)
        installed_casks=$("$brew_bin" list --cask -1) || return $?
        if [[ -n "$gui_kind" ]] || grep -Fxq -e tailscale-app -e tailscale <<<"$installed_casks"; then
            info 'A Tailscale Mac app is installed. Follow the macOS variant-switching instructions before choosing server: https://tailscale.com/docs/concepts/macos-variants'
            return 1
        fi
        "$brew_bin" install --formula tailscale
        tailscale_prefix=$("$brew_bin" --prefix tailscale)
        sudo "$brew_bin" services start tailscale
        if [[ "$login" == true ]] && has_terminal; then
            if ! sudo "$tailscale_prefix/bin/tailscale" status --peers=false >/dev/null 2>&1; then
                sudo "$tailscale_prefix/bin/tailscale" up
            fi
            info 'Tailscale server setup is complete. Verify access from another trusted device.'
        else
            info 'The daemon is installed and started. Finish sign-in with: sudo tailscale up'
        fi
        info 'After reviewing tailnet access rules, enable Tailscale SSH if wanted: sudo tailscale set --ssh'
        ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
