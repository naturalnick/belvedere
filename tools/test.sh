#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
godot --headless --path . --import > /tmp/shifting-manor-import.log 2>&1 || { cat /tmp/shifting-manor-import.log; exit 1; }
if grep -E 'SCRIPT ERROR|Parse Error|Compile Error' /tmp/shifting-manor-import.log; then exit 1; fi
godot --headless --path . --script res://tests/run_tests.gd
exec godot --headless --path . --script res://tests/scene_tests.gd -- --seed=A
