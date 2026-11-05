#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
python3 tools/check_export_identity.py
godot --headless --path . --import
exec godot --path . --script res://tools/conservatory_demo.gd
