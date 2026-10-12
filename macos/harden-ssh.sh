#!/usr/bin/env bash
# Harden Apple's Remote Login service; run separately from general Mac setup.
set -euo pipefail
umask 077

CONFIG=/etc/ssh/sshd_config
SNIPPETS=/etc/ssh/sshd_config.d
NAME=000-local-hardening.conf
TARGET="${SNIPPETS}/${NAME}"
DRY_RUN=0
LOGIN_USER=${SUDO_USER:-$(/usr/bin/id -un)}
WORK=''
STAGED=''
BACKUP=''
PENDING=0

die() {
	printf 'harden-ssh: %s\n' "$*" >&2
	exit 1
}

usage() {
	cat <<'EOF'
Usage: sudo bash macos/harden-ssh.sh [--user NAME] [--dry-run]

Require SSH keys for normal macOS logins, disable root/password login, and allow
only NAME (default: the user invoking sudo). Existing account restrictions apply.
Keep a working SSH session open and test a fresh SEP-key login afterward.

--dry-run  Validate and preview without changing system files; no sudo needed.
--user     Local account that has already tested SSH public-key login.
--help     Show this help.

Applies to Apple's Remote Login SSH server, not a separate Tailscale SSH server.
FileVault's preboot password-unlock service is also separate.
Does not change the firewall, Remote Login switch, forwarding, or SSH keys.
EOF
}

cleanup() {
	local status=$?
	trap - EXIT HUP INT TERM
	if ((PENDING)); then
		printf 'Validation failed or installation was interrupted; restoring the previous configuration.\n' >&2
		if [[ -n ${BACKUP} ]]; then
			if ! /bin/cp -p "${BACKUP}" "${STAGED}" || ! /bin/mv -f "${STAGED}" "${TARGET}"; then
				printf 'Automatic restore failed. Restore %s to %s manually.\n' "${BACKUP}" "${TARGET}" >&2
			fi
		elif ! /bin/rm -f "${TARGET}"; then
			printf 'Automatic restore failed. Remove %s manually.\n' "${TARGET}" >&2
		fi
		status=1
	fi
	[[ -z ${STAGED} ]] || /bin/rm -f "${STAGED}"
	[[ -z ${WORK} ]] || /bin/rm -rf "${WORK}"
	exit "${status}"
}

validate() {
	local config=$1
	local actual algorithms
	# OpenSSH 10.5 changed config dumps from lowercase to mixed-case keywords.
	actual=$(/usr/sbin/sshd -G -f "${config}" | /usr/bin/tr '[:upper:]' '[:lower:]') || return 1
	# Check effective values, so an earlier drop-in cannot silently win.
	while IFS= read -r expected; do
		if ! /usr/bin/grep -Fqx "${expected}" <<<"${actual}"; then
			printf 'Expected effective SSH setting: %s\n' "${expected}" >&2
			return 1
		fi
	done < <(/usr/bin/tr '[:upper:]' '[:lower:]' <"${WORK}/snippets/${NAME}" | /usr/bin/sed '/^#/d; /^$/d')
	[[ $(/usr/bin/grep -c '^allowusers ' <<<"${actual}") == 1 ]] || {
		printf 'Existing AllowUsers rules permit additional accounts; review them first.\n' >&2
		return 1
	}
	algorithms=$(/usr/bin/sed -n 's/^pubkeyacceptedalgorithms //p' <<<"${actual}")
	[[ ,${algorithms}, == *',sk-ecdsa-sha2-nistp256@openssh.com,'* ]] || {
		printf 'Existing PubkeyAcceptedAlgorithms excludes the native Secure Enclave SSH key; review it first.\n' >&2
		return 1
	}
}

print_login_checks() {
	cat <<EOF

Keep this session open. On your client Mac, replace MINI_LAN_IP with the mini's
LAN address and test the selected SEP key. This ignores SSH aliases, other keys,
and existing connection sharing:

  /usr/bin/ssh -F /dev/null -o ControlMaster=no -o ControlPath=none -o IdentitiesOnly=yes -o IdentityAgent=none -o IdentityFile=none -o SecurityKeyProvider=/usr/lib/ssh-keychain.dylib -o PubkeyAcceptedAlgorithms=sk-ecdsa-sha2-nistp256@openssh.com -o PreferredAuthentications=publickey -i ~/.ssh/id_ecdsa_sk_rk ${LOGIN_USER}@MINI_LAN_IP

After applying, verify that password-only login fails with "Permission denied (publickey)":

  /usr/bin/ssh -F /dev/null -o ControlMaster=no -o ControlPath=none -o PubkeyAuthentication=no -o PreferredAuthentications=password,keyboard-interactive ${LOGIN_USER}@MINI_LAN_IP

For the same SEP authentication over Tailscale, use ordinary SSH to the mini's
Tailscale address and allow TCP 22 in your tailnet grants. If Tailscale SSH is
enabled, disable it from the console or a working LAN session first:

  sudo tailscale set --ssh=false

Tailscale SSH has its own authentication policy and does not enforce this file
or your authorized_keys. Keep TCP 22 restricted to trusted LAN/VPN clients.

On macOS 26+, FileVault can accept an SSH password to unlock the disk before
the normal SSH configuration is available. Test that reboot/unlock path before
leaving the mini unattended. These settings apply after the disk is unlocked.
EOF
}

while (($#)); do
	case "$1" in
	--dry-run) DRY_RUN=1 ;;
	--user)
		(($# >= 2)) || die '--user requires an account name'
		LOGIN_USER=$2
		shift
		;;
	--help | -h)
		usage
		exit 0
		;;
	*) die "unknown option: $1 (try --help)" ;;
	esac
	shift
done

[[ $(/usr/bin/uname -s) == Darwin ]] || die 'this script requires macOS'
[[ ${LOGIN_USER} =~ ^[a-z_][a-z0-9_-]*$ ]] || die 'use a lowercase local account short name'
LOGIN_UID=$(/usr/bin/id -u "${LOGIN_USER}") || die "unknown account: ${LOGIN_USER}"
[[ ${LOGIN_UID} != 0 ]] || die 'choose a non-root login account'
if ((! DRY_RUN && EUID != 0)); then
	die 'run with sudo to apply, or use --dry-run to preview'
fi
[[ -d ${SNIPPETS} ]] || die "missing Apple drop-in directory: ${SNIPPETS}"
[[ ! -L ${TARGET} && (! -e ${TARGET} || -f ${TARGET}) ]] || die "refusing non-regular target: ${TARGET}"

WORK=$(/usr/bin/mktemp -d /private/tmp/harden-ssh.XXXXXX)
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
/bin/mkdir "${WORK}/snippets"
shopt -s nullglob
for snippet in "${SNIPPETS}"/*; do
	[[ -f ${snippet} ]] || die "unexpected entry in SSH configuration: ${snippet}"
	/bin/cp "${snippet}" "${WORK}/snippets/${snippet##*/}"
done

# Fail closed on custom connection-specific rules or uninspected includes.
# This script targets Apple's standard layout, including its crypto policy.
/usr/bin/awk '
	{ gsub(/=/, " ") }
	tolower($1) == "match" { print FILENAME ": custom Match rules require manual review"; bad=1 }
	tolower($1) == "include" && $2 != "/etc/ssh/sshd_config.d/*" && $2 != "/etc/ssh/crypto.conf" {
		print FILENAME ": custom Include requires manual review"; bad=1
	}
	tolower($1) == "include" && NF > 2 && $3 !~ /^#/ {
		print FILENAME ": multiple Include paths require manual review"; bad=1
	}
	END { exit bad }
' "${CONFIG}" "${WORK}"/snippets/* /etc/ssh/crypto.conf || die 'unsupported custom SSH configuration'

cat >"${WORK}/snippets/${NAME}" <<EOF
# Managed by dotfiles/macos/harden-ssh.sh.
PubkeyAuthentication yes
AuthenticationMethods publickey
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
UsePAM yes
StrictModes yes
AllowUsers ${LOGIN_USER}
MaxAuthTries 3
LoginGraceTime 30
EOF

# Preserve the real ordering of the main file and every drop-in for validation.
/usr/bin/awk -v staged="${WORK}/snippets/*" '
	tolower($1) == "include" && $2 == "/etc/ssh/sshd_config.d/*" {
		print "Include " staged; found++; next
	}
	{ print }
	END { if (found != 1) exit 1 }
' "${CONFIG}" >"${WORK}/sshd_config" || die 'expected exactly one standard macOS drop-in Include'
validate "${WORK}/sshd_config" || die 'candidate settings did not take effect'

printf 'SSH configuration for account %s:\n' "${LOGIN_USER}"
/bin/cat "${WORK}/snippets/${NAME}"
if ((DRY_RUN)); then
	printf '\nDry run passed. Apply with sudo to also validate host keys and install.\n'
	print_login_checks
	exit 0
fi

# Validate both the existing server and the complete candidate before any edit.
/usr/sbin/sshd -t -f "${CONFIG}"
/usr/sbin/sshd -t -f "${WORK}/sshd_config"
if [[ -f ${TARGET} ]] && /usr/bin/cmp -s "${WORK}/snippets/${NAME}" "${TARGET}"; then
	printf '\nAlready configured; no changes needed.\n'
	print_login_checks
	exit 0
fi

# Backups stay OUTSIDE sshd_config.d: Apple's Include glob loads every file.
if [[ -f ${TARGET} ]]; then
	BACKUP=$(/usr/bin/mktemp /etc/ssh/sshd-hardening-backup.XXXXXX)
	/bin/cp -p "${TARGET}" "${BACKUP}"
	printf '\nRollback: sudo /bin/cp -p %q %q\n' "${BACKUP}" "${TARGET}"
else
	printf '\nRollback: sudo /bin/rm -f %q\n' "${TARGET}"
fi

# Stage on the same filesystem, outside the Include glob, then rename atomically.
STAGED=$(/usr/bin/mktemp /etc/ssh/.sshd-hardening.XXXXXX)
/usr/bin/install -o root -g wheel -m 0644 "${WORK}/snippets/${NAME}" "${STAGED}"
PENDING=1
/bin/mv -f "${STAGED}" "${TARGET}"
/usr/sbin/sshd -t -f "${CONFIG}"
validate "${CONFIG}" || die 'installed settings did not take effect'
PENDING=0

printf "\nInstalled and validated. Apple's launchd reads the configuration on new connections.\n"
print_login_checks
printf '\nIf key login fails, use the rollback command above from this session or the console.\n'
printf 'These settings do not provide network-wide rate limiting under macOS launchd.\n'
