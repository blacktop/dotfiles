#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: ./lmstudio/lms.sh

Install LM Studio if needed, then offer each optional model separately.
For unattended downloads, set any of these to yes or no:
  SETUP_LMSTUDIO_QWEN38   Qwen3.8 27B, MLX 4-bit (~16.1 GB)
  SETUP_LMSTUDIO_GEMMA4   Gemma 4 12B, MLX 4-bit (~6.8 GB)
  SETUP_LMSTUDIO_GPT_OSS  gpt-oss-20B, GGUF MXFP4 (~12.1 GB)
USAGE
}

info() {
    printf '[lmstudio] %s\n' "$*" >&2
}

has_terminal() {
    [[ -t 0 && -t 1 ]]
}

app_installed() {
    [[ -d '/Applications/LM Studio.app' || -d "$HOME/Applications/LM Studio.app" ]] ||
        brew list --cask lm-studio >/dev/null 2>&1
}

offer_model() {
    local lms_bin="$1" installed_models="$2" model="$3" format="$4" description="$5" env_name="$6"
    local choice status

    if grep -Fxq -- "${model%@*}" <<<"$installed_models"; then
        info "${model%@*} is already downloaded"
        return 0
    fi

    choice=$(printf '%s' "${!env_name:-}" | tr '[:upper:]' '[:lower:]')
    case "$choice" in
    1 | true | yes | y) ;;
    0 | false | no | n)
        info "Skipping ${model%@*}"
        return 0
        ;;
    "")
        if ! has_terminal; then
            info "Skipping ${model%@*} (set $env_name=yes to download)"
            return 0
        fi
        if gum confirm --default=false "Download $description?"; then
            :
        else
            status=$?
            ((status == 1)) || return "$status"
            info "Skipping ${model%@*}"
            return 0
        fi
        ;;
    *)
        info "$env_name must be yes or no"
        return 2
        ;;
    esac

    "$lms_bin" get --yes "$format" "$model"
}

main() {
    if [[ $# -gt 0 ]]; then
        case "$1" in
        -h | --help)
            usage
            return 0
            ;;
        *)
            usage >&2
            return 2
            ;;
        esac
    fi

    info 'Setup LM Studio'
    if app_installed; then
        info 'LM Studio is already installed'
    else
        brew install --cask lm-studio
    fi

    local lms_bin installed_json installed_models count=0
    lms_bin=$(command -v lms || true)
    lms_bin=${lms_bin:-"$HOME/.lmstudio/bin/lms"}
    if [[ ! -x "$lms_bin" ]]; then
        info 'Initializing LM Studio (first launch)...'
        open -a 'LM Studio'
        while [[ ! -x "$lms_bin" && $count -lt 30 ]]; do
            sleep 1
            count=$((count + 1))
        done
        if [[ ! -x "$lms_bin" ]]; then
            info 'Launch LM Studio manually, then rerun this script.'
            return 1
        fi
    fi

    if ! has_terminal && [[ -z "${SETUP_LMSTUDIO_QWEN38:-}${SETUP_LMSTUDIO_GEMMA4:-}${SETUP_LMSTUDIO_GPT_OSS:-}" ]]; then
        info 'No model downloads selected. Run ./lmstudio/lms.sh in a terminal or use the options in --help.'
        return 0
    fi

    # Use LM Studio's inventory so custom model directories are respected.
    # Models available only through LM Link are not installed on this Mac.
    installed_json=$("$lms_bin" ls --json)
    installed_models=$(jq -r 'if type != "array" then error("expected a model list") else
        .[] | select(.deviceIdentifier == null) | .modelKey | split("@")[0]
    end' <<<"$installed_json")

    info 'Selected for a 32 GB Apple Silicon Mac. Larger contexts and concurrent models need more RAM.'
    # Catalog reviewed 2026-10-11: https://lmstudio.ai/models?sort=downloads&dir=desc
    offer_model "$lms_bin" "$installed_models" 'qwen/qwen3.8-27b@4bit' --mlx \
        'Qwen3.8 27B for coding and agents (MLX 4-bit, ~16.1 GB)' SETUP_LMSTUDIO_QWEN38
    offer_model "$lms_bin" "$installed_models" 'google/gemma-4-12b@4bit' --mlx \
        'Gemma 4 12B for everyday chat and images (MLX 4-bit, ~6.8 GB)' SETUP_LMSTUDIO_GEMMA4
    offer_model "$lms_bin" "$installed_models" 'openai/gpt-oss-20b@mxfp4' --gguf \
        'gpt-oss-20B for reasoning and tool use (GGUF MXFP4, ~12.1 GB)' SETUP_LMSTUDIO_GPT_OSS
}

main "$@"
