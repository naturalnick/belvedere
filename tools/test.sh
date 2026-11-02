#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
RUN_LOG="$(mktemp -t shifting-manor-tests)"
trap 'rm -f "$RUN_LOG"' EXIT HUP INT TERM
run_checked() {
    godot --headless --path . "$@" > "$RUN_LOG" 2>&1 || { cat "$RUN_LOG"; exit 1; }
    cat "$RUN_LOG"
    if grep -E 'SCRIPT ERROR|^ERROR:|FAIL:' "$RUN_LOG"; then exit 1; fi
}
run_checked --import
run_checked --script res://tests/run_tests.gd
run_checked --script res://tests/scene_tests.gd -- --classic --seed=A
run_checked --script res://tests/courtyard_tests.gd
