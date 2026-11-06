#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
exec godot --headless --path . --script res://tools/gen_godot_notices.gd
