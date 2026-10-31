function codex -w codex -d 'Codex CLI with Rex receipt ownership'
    switch "$CODEX_HOME"
        case '' "$HOME/.codex"
            rexurrect-launch codex codex $argv
        case '*'
            set -fx RR_HARNESS ''
            set -fx RR_HOST ''
            set -fx RR_LAUNCHER_PID ''
            command codex $argv
    end
end
