# shellcheck shell=sh
# Opt-outs for setup processes and their children. Go uses `go telemetry off`.
export DO_NOT_TRACK=1
export DISABLE_TELEMETRY=1
export DISABLE_ERROR_REPORTING=1
export HOMEBREW_NO_ANALYTICS=1
export SEMGREP_SEND_METRICS=off
export KACHE_RECORD_SESSIONS=0
