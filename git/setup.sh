#!/bin/sh
set -o errexit -o nounset

echo "$(gum style --bold --foreground "#6F08B2" " ⇒ ") $(gum style --bold "Setup Git")"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# TTY guard — gum prompts require an interactive terminal
has_tty() { command -v gum >/dev/null 2>&1 && [ -t 0 ] && [ -t 1 ]; }

# ── GitHub CLI auth (needed for credential helper, SSH key upload, plugins) ──
if command -v gh >/dev/null 2>&1; then
    if ! gh auth status >/dev/null 2>&1; then
        if has_tty; then
            echo "$(gum style --bold --foreground "#FF9400" "[choose]") $(gum style --bold "Log in to GitHub CLI? (needed for git push, SSH key upload)")"
            CHOICE=$(gum choose --cursor.foreground "#FF9400" --item.foreground "#F7BA00" "Yes" "No")
            if [ "$CHOICE" = "Yes" ]; then
                gh auth login
            else
                echo "$(gum style --faint "      ⚠ Skipped — run 'gh auth login' later for full GitHub integration")"
            fi
        else
            echo "  ⚠ gh not authenticated (run 'gh auth login' in an interactive terminal)"
        fi
    else
        echo "$(gum style --bold --foreground "#00C853" "  ✓") GitHub CLI already authenticated"
    fi
fi

# ── Core ─────────────────────────────────────────────────────────────────────
git config --global core.editor "code -w -n"
git config --global core.pager delta
git config --global core.excludesFile "$HOME/.gitignore_global"

# ── User ─────────────────────────────────────────────────────────────────────
git config --global user.name "blacktop"
git config --global user.email "blacktop@users.noreply.github.com"

# ── Push / Pull / Rebase ────────────────────────────────────────────────────
git config --global push.autoSetupRemote true
git config --global push.default current
git config --global pull.rebase true
git config --global rebase.autoStash true
git config --global init.defaultBranch main

# ── Aliases ──────────────────────────────────────────────────────────────────
git config --global alias.undo "reset --soft HEAD^"

# ── Diff ─────────────────────────────────────────────────────────────────────
git config --global diff.ignoreSubmodules dirty

# ── Delta (pager) ────────────────────────────────────────────────────────────
git config --global delta.line-numbers true
git config --global delta.decorations true
git config --global delta.navigate true
git config --global delta.light false
git config --global delta.side-by-side true
git config --global delta.colorMoved default

# ── Git LFS ──────────────────────────────────────────────────────────────────
git config --global filter.lfs.clean "git-lfs clean -- %f"
git config --global filter.lfs.smudge "git-lfs smudge -- %f"
git config --global filter.lfs.process "git-lfs filter-process"
git config --global filter.lfs.required true

# ── GitHub credential helper (gh CLI) ────────────────────────────────────────
git config --global credential.https://github.com.helper ""
git config --global credential.https://github.com.helper "!/opt/homebrew/bin/gh auth git-credential"
git config --global credential.https://gist.github.com.helper ""
git config --global credential.https://gist.github.com.helper "!/opt/homebrew/bin/gh auth git-credential"

# ── Global gitignore ────────────────────────────────────────────────────────
ln -sf "$SCRIPT_DIR/gitignore_global" "$HOME/.gitignore_global"

# ── SSH key (Secure Enclave) ──────────────────────────────────────────────────
# Non-exportable ECDSA key backed by the Secure Enclave Processor.
# Private key never leaves hardware; signing requires Touch ID.
# Split into three independent steps so reruns can retry export/upload.

SEP_PUB_KEY="$HOME/.ssh/id_ecdsa_sk_rk.pub"
SSH_CONFIG="$HOME/.ssh/config"

# Step 1: Create CTK identity (only if none exists)
if [ -z "$(sc_auth list-ctk-identities -t ssh 2>/dev/null | grep -v '^Key Type')" ]; then
    if has_tty; then
        echo "$(gum style --bold --foreground "#FF9400" "[choose]") $(gum style --bold "Create Secure Enclave SSH key? (Touch ID required)")"
        CHOICE=$(gum choose --cursor.foreground "#FF9400" --item.foreground "#F7BA00" "Yes" "No")
        if [ "$CHOICE" = "Yes" ]; then
            echo "$(gum style --bold --foreground "#BE05D0" "  -") Creating Secure Enclave SSH key..."
            sc_auth create-ctk-identity -k p-256-ne -t bio -l "ssh"
        fi
    else
        echo "  ⚠ Skipping Secure Enclave SSH key (requires interactive terminal + Touch ID)"
    fi
else
    echo "$(gum style --bold --foreground "#00C853" "  ✓") Secure Enclave SSH key already exists"
fi

# Step 2: Export public key stub (idempotent — reruns if pub key is missing)
if [ -n "$(sc_auth list-ctk-identities -t ssh 2>/dev/null | grep -v '^Key Type')" ] && [ ! -f "$SEP_PUB_KEY" ]; then
    echo "$(gum style --bold --foreground "#BE05D0" "  -") Extracting public key from Secure Enclave..."
    mkdir -p "$HOME/.ssh"
    cd "$HOME/.ssh"
    SSH_ASKPASS_REQUIRE=force SSH_ASKPASS=true \
        ssh-keygen -w /usr/lib/ssh-keychain.dylib -K
    cd - >/dev/null
fi

# Step 3: Configure SSH client (idempotent)
if [ -f "$SEP_PUB_KEY" ]; then
    # Add SecurityKeyProvider so OpenSSH talks to Secure Enclave
    if ! grep -q 'SecurityKeyProvider' "$SSH_CONFIG" 2>/dev/null; then
        {
            echo ""
            echo "# Secure Enclave SSH key (Touch ID)"
            echo "Host *"
            echo "    SecurityKeyProvider /usr/lib/ssh-keychain.dylib"
        } >>"$SSH_CONFIG"
        chmod 600 "$SSH_CONFIG"
    fi

    # Register the resident key filename so OpenSSH auto-loads it
    if ! grep -q 'id_ecdsa_sk_rk' "$SSH_CONFIG" 2>/dev/null; then
        {
            echo "    IdentityFile ~/.ssh/id_ecdsa_sk_rk"
        } >>"$SSH_CONFIG"
    fi

    # Upload to GitHub
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        HOSTNAME=$(scutil --get ComputerName 2>/dev/null || hostname -s)
        GH_OUTPUT=$(gh ssh-key add "$SEP_PUB_KEY" --title "SEP-$HOSTNAME-$(date +%Y)" 2>&1) && {
            echo "$(gum style --bold --foreground "#00C853" "  ✓") SSH key added to GitHub"
        } || {
            if echo "$GH_OUTPUT" | grep -qi 'already'; then
                echo "$(gum style --bold --foreground "#00C853" "  ✓") SSH key already on GitHub"
            else
                echo "$(gum style --bold --foreground "#FF9400" "  ⚠") Failed to upload SSH key: $GH_OUTPUT"
            fi
        }
    else
        echo "$(gum style --bold --foreground "#FF9400" "  ⚠") Run 'gh auth login' then rerun this script to upload SSH key to GitHub"
    fi
fi

# ── gh-dash ──────────────────────────────────────────────────────────────────
# echo "$(gum style --bold --foreground "#BE05D0" "  -") Install gh-dash..."
# gh extension install dlvhdr/gh-dash
# mkdir -p "$HOME/.config/gh-dash"
# cp -r "$SCRIPT_DIR/gh-dash/"* "$HOME/.config/gh-dash/"
