#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TARGET_MACOS_MAJOR=26
MODE="${MACOS_SETUP_MODE:-}"
DRY_RUN=0
SUDO_READY=0
APPLIED_COUNT=0
SKIPPED_COUNT=0
PREFERENCES_CHANGED=0
RESTART_DOCK=0
RESTART_FINDER=0
RESTART_SYSTEM_UI=0
GUM="$(command -v gum || true)"

usage() {
	cat <<'EOF'
Usage: macos/setup.sh [--all | --review] [--dry-run]
                      [--list | --help | --version]

Configure a personal Mac running macOS 26 Tahoe.

Modes:
  --all       Apply every section without per-section confirmation.
  --review    Ask before applying each section (requires Gum and a TTY).

Options:
  --dry-run   Print commands without changing the Mac or requesting sudo.
  --list      List configurable sections and exit.
  --help      Show this help text and exit.
  --version   Show the target macOS release and exit.

With no mode, an interactive Gum survey offers Apply all, Review each, or
Cancel. For unattended use, pass --all or set MACOS_SETUP_MODE=all.
EOF
}

list_sections() {
	cat <<'EOF'
General UI and input
Accessibility: Speak Selection
Screenshots
Finder
Desktop, Dock, and window tiling
Safari developer and privacy settings
TextEdit
Automatic software updates
Terminal
Touch ID for sudo
Time Machine exclusions
EOF
}

has_gum_ui() {
	[[ -n "${GUM}" && -t 0 && -t 1 ]]
}

heading() {
	if has_gum_ui; then
		"${GUM}" style --bold --foreground '#6F08B2' -- " ⇒  $*"
	else
		printf '\n==> %s\n' "$*"
	fi
}

info() {
	printf '  • %s\n' "$*"
}

ok() {
	printf '  ✓ %s\n' "$*"
}

warn() {
	printf '  ! %s\n' "$*" >&2
}

die() {
	printf 'macos/setup.sh: %s\n' "$*" >&2
	exit 1
}

print_command() {
	printf '  +'
	printf ' %q' "$@"
	printf '\n'
}

run() {
	if ((DRY_RUN)); then
		print_command "$@"
	else
		"$@"
	fi
}

run_quietly() {
	if ((DRY_RUN)); then
		print_command "$@"
	else
		"$@" >/dev/null 2>&1 || true
	fi
}

ensure_sudo() {
	if ((SUDO_READY)); then
		return
	fi

	if ((DRY_RUN)); then
		print_command /usr/bin/sudo -v
	else
		/usr/bin/sudo -v
	fi
	SUDO_READY=1
}

sudo_run() {
	ensure_sudo
	if ((DRY_RUN)); then
		print_command /usr/bin/sudo "$@"
	else
		/usr/bin/sudo "$@"
	fi
}

defaults_write() {
	run /usr/bin/defaults write "$@"
	PREFERENCES_CHANGED=1
}

sudo_defaults_write() {
	sudo_run /usr/bin/defaults write "$@"
}

quit_app() {
	local app_name=$1
	run_quietly /usr/bin/osascript -e "tell application \"${app_name}\" to quit"
}

choose_mode() {
	local choice

	case "${MODE}" in
	all | review) return ;;
	'') ;;
	*) die "invalid mode '${MODE}'; expected all or review" ;;
	esac

	has_gum_ui || die "interactive mode requires Gum and a TTY; use --all for unattended setup"

	if ! choice=$("${GUM}" choose \
		--header 'How should macOS settings be applied?' \
		--cursor.foreground '#FF9400' \
		--item.foreground '#F7BA00' \
		'Apply all sections' \
		'Review each section' \
		'Cancel'); then
		exit 130
	fi

	case "${choice}" in
	'Apply all sections') MODE=all ;;
	'Review each section') MODE=review ;;
	'Cancel') exit 0 ;;
	*) die "unexpected Gum selection: ${choice}" ;;
	esac
}

approve_section() {
	local title=$1
	local description=$2
	local status

	if [[ "${MODE}" == all ]]; then
		return 0
	fi

	if "${GUM}" confirm "${title} — ${description}" \
		--affirmative 'Apply' \
		--negative 'Skip' \
		--prompt.foreground '#FF9400' \
		--selected.background '#FF9400' \
		--selected.foreground '#230' \
		--unselected.foreground '#F7BA00'; then
		return 0
	else
		status=$?
	fi

	if ((status == 130)); then
		exit 130
	fi
	return 1
}

run_section() {
	local title=$1
	local description=$2
	local function_name=$3

	if approve_section "${title}" "${description}"; then
		heading "${title}"
		info "${description}"
		"${function_name}"
		APPLIED_COUNT=$((APPLIED_COUNT + 1))
		ok "${title} complete"
	else
		SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
		info "Skipped ${title}"
	fi
}

configure_general_input() {
	defaults_write com.apple.print.PrintingPrefs 'Quit When Finished' -bool true
	sudo_defaults_write /Library/Preferences/com.apple.loginwindow AdminHostInfo -string HostName

	defaults_write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
	defaults_write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
	defaults_write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
	defaults_write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
	defaults_write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
	defaults_write NSGlobalDomain AppleKeyboardUIMode -int 3
	defaults_write NSGlobalDomain com.apple.swipescrolldirection -bool false

	defaults_write com.apple.AppleMultitouchTrackpad Clicking -bool true
	defaults_write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
	run /usr/bin/defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
	defaults_write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
	defaults_write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
	defaults_write com.apple.AppleMultitouchTrackpad HIDScrollZoomModifierMask -int 262144
	defaults_write com.apple.driver.AppleBluetoothMultitouch.trackpad HIDScrollZoomModifierMask -int 262144
	RESTART_SYSTEM_UI=1
}

configure_accessibility() {
	defaults_write com.apple.speech.synthesis.general.prefs SpokenUIUseSpeakingHotKeyFlag -bool true
	defaults_write com.apple.speech.synthesis.general.prefs SpokenUIUseSpeakingHotKeyCombo -int 2101
	defaults_write com.apple.Accessibility AccessibilityEnabled -int 1
	defaults_write com.apple.Accessibility ApplicationAccessibilityEnabled -int 1
	defaults_write com.apple.Accessibility SpeakThisEnabled -int 1
	RESTART_SYSTEM_UI=1
}

configure_screenshots() {
	local screenshot_dir="${HOME}/Downloads/Screenshots"
	run /bin/mkdir -p "${screenshot_dir}"
	defaults_write com.apple.screencapture location -string "${screenshot_dir}"
	defaults_write com.apple.screencapture type -string png
	RESTART_SYSTEM_UI=1
}

configure_finder() {
	defaults_write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
	defaults_write com.apple.finder ShowHardDrivesOnDesktop -bool true
	defaults_write com.apple.finder ShowMountedServersOnDesktop -bool true
	defaults_write com.apple.finder ShowRemovableMediaOnDesktop -bool true
	defaults_write NSGlobalDomain AppleShowAllExtensions -bool true
	defaults_write com.apple.finder ShowStatusBar -bool true
	defaults_write com.apple.finder ShowPathbar -bool true
	defaults_write com.apple.finder FXDefaultSearchScope -string SCcf
	defaults_write com.apple.desktopservices DSDontWriteNetworkStores -bool true
	defaults_write com.apple.desktopservices DSDontWriteUSBStores -bool true
	defaults_write com.apple.frameworks.diskimages auto-open-ro-root -bool true
	defaults_write com.apple.frameworks.diskimages auto-open-rw-root -bool true
	defaults_write com.apple.finder OpenWindowForNewRemovableDisk -bool true
	defaults_write com.apple.finder FXPreferredViewStyle -string Nlsv
	run /bin/chflags nohidden "${HOME}/Library"
	if ((DRY_RUN)); then
		print_command /usr/bin/xattr -d com.apple.FinderInfo "${HOME}/Library"
	else
		/usr/bin/xattr -d com.apple.FinderInfo "${HOME}/Library" >/dev/null 2>&1 || true
	fi
	RESTART_FINDER=1
}

configure_dock() {
	defaults_write com.apple.dock largesize -int 128
	defaults_write com.apple.dock tilesize -int 16
	defaults_write com.apple.dock magnification -bool true
	defaults_write com.apple.dock minimize-to-application -bool true
	defaults_write com.apple.dock mru-spaces -bool false
	defaults_write com.apple.dock show-recents -bool false

	# Tahoe stores window-tiling preferences in WindowManager, not the Dock.
	defaults_write com.apple.WindowManager EnableTiledWindowMargins -bool false

	defaults_write com.apple.dock wvous-tr-corner -int 4
	defaults_write com.apple.dock wvous-tr-modifier -int 0
	RESTART_DOCK=1
}

configure_safari() {
	local safaridriver
	quit_app Safari

	safaridriver=$(command -v safaridriver || true)
	if [[ -n "${safaridriver}" ]]; then
		run "${safaridriver}" --enable
	else
		warn 'safaridriver was not found; remote automation was not enabled'
	fi

	defaults_write com.apple.Safari IncludeDevelopMenu -bool true
	defaults_write NSGlobalDomain WebKitDeveloperExtras -bool true
	defaults_write com.apple.Safari UniversalSearchEnabled -bool false
	defaults_write com.apple.Safari SuppressSearchSuggestions -bool true
	defaults_write com.apple.Safari ShowFullURLInSmartSearchField -bool true
	defaults_write com.apple.Safari HomePage -string about:blank
	defaults_write com.apple.Safari AutoOpenSafeDownloads -bool false
	defaults_write com.apple.Safari ShowFavoritesBar -bool false
	defaults_write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true
	defaults_write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false
	defaults_write com.apple.Safari AutoFillFromAddressBook -bool false
	defaults_write com.apple.Safari AutoFillPasswords -bool false
	defaults_write com.apple.Safari AutoFillCreditCardData -bool false
	defaults_write com.apple.Safari AutoFillMiscellaneousForms -bool false
	defaults_write com.apple.Safari WarnAboutFraudulentWebsites -bool true
	defaults_write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
}

configure_textedit() {
	quit_app TextEdit
	defaults_write com.apple.TextEdit RichText -int 0
	defaults_write com.apple.TextEdit PlainTextEncoding -int 4
	defaults_write com.apple.TextEdit PlainTextEncodingForWrite -int 4
	defaults_write com.apple.TextEdit TabWidth -int 4
}

configure_updates() {
	sudo_defaults_write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
	sudo_defaults_write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
	sudo_defaults_write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
	sudo_defaults_write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
	sudo_defaults_write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
	defaults_write com.apple.commerce AutoUpdate -bool true
}

configure_terminal() {
	local theme="${REPO_ROOT}/init/Nord.terminal"
	defaults_write com.apple.Terminal StringEncodings -array 4
	defaults_write com.apple.Terminal SecureKeyboardEntry -bool true
	defaults_write com.apple.Terminal ShowLineMarks -int 0

	if [[ -f "${theme}" ]]; then
		run /usr/bin/open "${theme}"
		if ((!DRY_RUN)); then
			/bin/sleep 1
		fi
		defaults_write com.apple.Terminal 'Default Window Settings' -string Nord
		defaults_write com.apple.Terminal 'Startup Window Settings' -string Nord
	else
		warn "Terminal theme not found: ${theme}"
	fi
}

configure_touchid() {
	local pam_file=/etc/pam.d/sudo_local
	local pam_template=/etc/pam.d/sudo_local.template
	local source_file=${pam_file}
	local pam_tmp
	local reattach_line=''

	if ((DRY_RUN)); then
		ensure_sudo
		info 'Would rebuild /etc/pam.d/sudo_local with pam_reattach before pam_tid'
		return
	fi

	if [[ ! -f "${source_file}" ]]; then
		source_file=${pam_template}
	fi
	[[ -f "${source_file}" ]] || die 'neither sudo_local nor sudo_local.template exists'

	if [[ -f /opt/homebrew/lib/pam/pam_reattach.so ]]; then
		reattach_line='auth       optional       /opt/homebrew/lib/pam/pam_reattach.so ignore_ssh'
	fi

	pam_tmp=$(/usr/bin/mktemp -t dotfiles-sudo-local)
	if ! /usr/bin/awk -v reattach="${reattach_line}" '
		index($0, "pam_reattach.so") { next }
		$0 ~ /^[[:space:]]*#?[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so([[:space:]]|$)/ { next }
		{ print }
		END {
			if (reattach != "") print reattach
			print "auth       sufficient     pam_tid.so"
		}
	' "${source_file}" >"${pam_tmp}"; then
		/bin/rm -f "${pam_tmp}"
		die 'failed to construct sudo_local'
	fi

	ensure_sudo
	if ! /usr/bin/sudo /usr/bin/install -o root -g wheel -m 0644 "${pam_tmp}" "${pam_file}"; then
		/bin/rm -f "${pam_tmp}"
		die 'failed to install sudo_local'
	fi
	/bin/rm -f "${pam_tmp}"
}

configure_time_machine() {
	[[ -x "${SCRIPT_DIR}/tm.sh" ]] || die "missing executable: ${SCRIPT_DIR}/tm.sh"
	run "${SCRIPT_DIR}/tm.sh"
}

finalize_preferences() {
	if ((PREFERENCES_CHANGED)); then
		run_quietly /usr/bin/killall cfprefsd
	fi
	if ((RESTART_FINDER)); then
		run_quietly /usr/bin/killall Finder
	fi
	if ((RESTART_DOCK)); then
		run_quietly /usr/bin/killall Dock
	fi
	if ((RESTART_SYSTEM_UI)); then
		run_quietly /usr/bin/killall SystemUIServer
	fi
}

while (($#)); do
	case "$1" in
	--all)
		[[ -z "${MODE}" || "${MODE}" == all ]] || die '--all conflicts with --review or MACOS_SETUP_MODE'
		MODE=all
		;;
	--review)
		[[ -z "${MODE}" || "${MODE}" == review ]] || die '--review conflicts with --all or MACOS_SETUP_MODE'
		MODE=review
		;;
	--dry-run)
		DRY_RUN=1
		;;
	--list)
		list_sections
		exit 0
		;;
	--help | -h)
		usage
		exit 0
		;;
	--version)
		printf 'macos-setup (target: macOS %s Tahoe)\n' "${TARGET_MACOS_MAJOR}"
		exit 0
		;;
	*)
		die "unknown option: $1 (try --help)"
		;;
	esac
	shift
done

[[ $(/usr/bin/uname -s) == Darwin ]] || die 'this script only supports macOS'
((EUID != 0)) || die 'run as your login user; the script invokes sudo only where needed'

macos_version=$(/usr/bin/sw_vers -productVersion)
macos_major=${macos_version%%.*}
[[ ${macos_major} =~ ^[0-9]+$ ]] || die "could not parse macOS version: ${macos_version}"
((macos_major >= TARGET_MACOS_MAJOR)) || die "macOS ${TARGET_MACOS_MAJOR} Tahoe or newer is required"
if ((macos_major > TARGET_MACOS_MAJOR)); then
	warn "macOS ${macos_version} is newer than the verified Tahoe target; review with --dry-run first"
fi

choose_mode
if [[ ${MODE} == review ]]; then
	has_gum_ui || die '--review requires Gum and an interactive TTY'
fi

heading "Setup macOS ${macos_version}"
if ((DRY_RUN)); then
	warn 'Dry run: commands will be printed but not executed'
fi

# Apple recommends changing app preferences while the target app is not running.
quit_app 'System Settings'
quit_app 'System Preferences'

run_section \
	'General UI and input' \
	'Developer-friendly typing, trackpad, keyboard navigation, scrolling, and login-window info.' \
	configure_general_input
run_section \
	'Accessibility: Speak Selection' \
	'Enable the system Speak Selection shortcut without pinning a host-specific voice ID.' \
	configure_accessibility
run_section \
	'Screenshots' \
	'Save PNG screenshots under ~/Downloads/Screenshots.' \
	configure_screenshots
run_section \
	'Finder' \
	'Show useful metadata and devices, default to list view, and avoid network/USB .DS_Store files.' \
	configure_finder
run_section \
	'Desktop, Dock, and window tiling' \
	'Use a compact magnifying Dock, stable Spaces, no recent apps, gapless tiling, and a Desktop hot corner.' \
	configure_dock
run_section \
	'Safari developer and privacy settings' \
	'Enable supported WebDriver tooling and apply a small set of current Safari preferences.' \
	configure_safari
run_section \
	'TextEdit' \
	'Default to UTF-8 plain text with four-space tabs.' \
	configure_textedit
run_section \
	'Automatic software updates' \
	'Enable automatic checks, downloads, macOS installs, security data, and App Store updates.' \
	configure_updates
run_section \
	'Terminal' \
	'Use UTF-8, Secure Keyboard Entry, no line marks, and the checked-in Nord profile.' \
	configure_terminal
run_section \
	'Touch ID for sudo' \
	'Build an update-safe sudo_local PAM file, with pam_reattach before pam_tid when installed.' \
	configure_touchid
run_section \
	'Time Machine exclusions' \
	'Apply fixed-path exclusions for regenerable caches, toolchains, package stores, and build output.' \
	configure_time_machine

finalize_preferences

heading 'macOS setup complete'
printf 'Applied: %d  Skipped: %d  Mode: %s' "${APPLIED_COUNT}" "${SKIPPED_COUNT}" "${MODE}"
if ((DRY_RUN)); then
	printf '  (dry run)'
fi
printf '\n'
info 'Some input, accessibility, and login-window changes may require logout or restart.'
