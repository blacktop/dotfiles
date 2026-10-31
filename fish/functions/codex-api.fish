function codex-api -w codex -d 'Codex CLI using the API-key account'
    # rexurrect has no codex-api receipt identity; keep this account manual.
    set -fx RR_HARNESS ''
    CODEX_HOME=$HOME/.codex-api command codex $argv
end
