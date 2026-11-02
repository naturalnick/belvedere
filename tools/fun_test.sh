#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
RUN_LOG="$(mktemp -t shifting-manor-fun)"
trap 'rm -f "$RUN_LOG"' EXIT HUP INT TERM
run_checked() {
    godot --headless --path . "$@" > "$RUN_LOG" 2>&1 || { cat "$RUN_LOG"; exit 1; }
    cat "$RUN_LOG"
    if grep -E 'SCRIPT ERROR|^ERROR:|FAIL:' "$RUN_LOG"; then exit 1; fi
}
run_checked --import
run_checked --script res://tools/fun/benchmark.gd
run_checked --script res://tools/fun/probes.gd -- --classic --seed=A
python3 tools/fun/report.py
