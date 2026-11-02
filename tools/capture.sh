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
exec godot --path . -- --demo --mode="$MODE" --seed="$SEED" --shots="$OUT" "$@"
