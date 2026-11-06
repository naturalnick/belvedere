#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
MODE="${1:-single-gap}"
SEED="${2:-A}"
OUT="${3:-screenshots/$MODE}"
[ "$#" -gt 3 ] && shift 3 || shift "$#"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
godot --headless --path . --import > /tmp/belvedere-import.log 2>&1 || { cat /tmp/belvedere-import.log; exit 1; }
if grep -E 'SCRIPT ERROR|Parse Error|Compile Error' /tmp/belvedere-import.log; then exit 1; fi
if [ "$MODE" = "drawers" ]; then
    exec godot --path . --script res://tests/drawer_tests.gd -- --shots="$OUT" "$@"
fi
exec godot --path . -- --demo --mode="$MODE" --seed="$SEED" --shots="$OUT" "$@"
