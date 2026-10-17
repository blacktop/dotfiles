function codex -w codex -d 'Codex CLI with explicit Rex resume receipts'
    switch "$CODEX_HOME"
        case '' "$HOME/.codex"
            _rexurrect_codex codex $argv
        case '*'
            command codex $argv
    end
end
