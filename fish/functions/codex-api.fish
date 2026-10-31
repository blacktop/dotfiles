function codex-api -w codex -d 'Codex CLI using the API-key account'
    # Keep API-key launches manual.
    set -fx RR_HARNESS ''
    set -fx RR_HOST ''
    set -fx RR_LAUNCHER_PID ''
    CODEX_HOME=$HOME/.codex-api command codex $argv
end
