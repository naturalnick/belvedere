#!/bin/sh
# Builds only local files: unsigned and unnotarized, with no upload or publishing step.
set -eu
cd "$(dirname "$0")/.."
python3 tools/check_export_identity.py
mkdir -p build/macos
OUTPUT="$(pwd)/build/macos/Belvedere-test.zip"
rm -f "$OUTPUT"
godot --headless --path . --import
godot --headless --path . --export-release "macOS Unsigned Test" "$OUTPUT"
# Godot exits 0 when a preset fails its configuration checks, so check for the file instead.
test -s "$OUTPUT"
echo "Built $OUTPUT"
