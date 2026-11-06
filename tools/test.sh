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
run_checked --script res://tests/scene_tests.gd -- --seed=C
run_checked --script res://tests/single_gap_tests.gd
run_checked --script res://tests/wall_geometry_tests.gd
run_checked --script res://tests/door_geometry_tests.gd
run_checked --script res://tests/objective_tests.gd
run_checked --script res://tests/coin_tests.gd
run_checked --script res://tests/drawer_tests.gd
run_checked --script res://tests/safe_tests.gd
run_checked --script res://tests/binocular_tests.gd
run_checked --script res://tests/stopwatch_tests.gd
run_checked --script res://tests/conservatory_tests.gd
run_checked --script res://tests/ending_tests.gd
run_checked --script res://tests/run_stats_tests.gd
run_checked --script res://tests/title_tests.gd
run_checked --script res://tests/pointer_tests.gd
run_checked --script res://tests/pointer_tests.gd -- --web-entry
run_checked --script res://tests/settings_tests.gd
run_checked --script res://tests/bedroom_tests.gd
run_checked --script res://tests/bed_sleep_tests.gd
run_checked --script res://tests/bed_sleep_tests.gd -- --web-entry
run_checked --script res://tests/bed_sleep_tests.gd -- --seed=B
run_checked --script res://tests/furnishing_tests.gd
run_checked --script res://tests/plan_tests.gd
run_checked --script res://tests/shadow_tests.gd
run_checked --script res://tests/vegetation_tests.gd
run_checked --script res://tests/slide_motion_tests.gd
run_checked --script res://tests/door_motion_tests.gd
run_checked --script res://tests/reticle_tests.gd
run_checked --script res://tests/fall_recovery_tests.gd
run_checked --script res://tests/audio_tests.gd
run_checked --script res://tests/web_startup_tests.gd
run_checked --script res://tests/frame_rate_tests.gd
