#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
MODE="${1:-solve}"
SEED="${2:-A}"
OUT="${3:-screenshots/stage1}"
[ "$#" -gt 3 ] && shift 3 || shift "$#"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
godot --headless --path . --import > /tmp/shifting-manor-import.log 2>&1 || { cat /tmp/shifting-manor-import.log; exit 1; }
if grep -E 'SCRIPT ERROR|Parse Error|Compile Error' /tmp/shifting-manor-import.log; then exit 1; fi
if [ "$MODE" = "drawers" ]; then
    exec godot --path . --script res://tests/drawer_tests.gd -- --shots="$OUT" "$@"
fi
CLASSIC="--classic"
if [ "$MODE" = "courtyard" ]; then CLASSIC="--courtyard"; fi
if [ "$MODE" = "conservatory" ] || [ "$MODE" = "sleep" ] || [ "$MODE" = "stopwatch" ] || [ "$MODE" = "single-gap" ] || [ "$MODE" = "objectives" ] || [ "$MODE" = "stage3" ] || [ "$MODE" = "furnishings" ] || [ "$MODE" = "trees" ] || [ "$MODE" = "exterior" ] || [ "$MODE" = "fall" ] || [ "$MODE" = "coins" ] || [ "$MODE" = "title" ] || [ "$MODE" = "safe" ] || [ "$MODE" = "binoculars" ]; then CLASSIC=""; fi
exec godot --path . -- $CLASSIC --demo --mode="$MODE" --seed="$SEED" --shots="$OUT" "$@"
