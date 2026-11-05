#!/bin/sh
# Builds only local files: unsigned, with no upload or publishing step.
set -eu
cd "$(dirname "$0")/.."
python3 tools/check_export_identity.py
mkdir -p build/windows
STAGING="$(mktemp -d "$(pwd)/build/windows/staging.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT HUP INT TERM
godot --headless --path . --import
godot --headless --path . --export-release "Windows Test" "$STAGING/Belvedere.exe"
cp LICENSE.txt "$STAGING/LICENSE.txt"
cp docs/CREDITS.md "$STAGING/CREDITS.md"
cp assets/fonts/Fondamento-OFL.txt "$STAGING/Fondamento-OFL.txt"
rm -f build/windows/belvedere-windows.zip
(cd "$STAGING" && zip -q -X "../belvedere-windows.zip" Belvedere.exe LICENSE.txt CREDITS.md Fondamento-OFL.txt)
echo "Built $(pwd)/build/windows/belvedere-windows.zip"
