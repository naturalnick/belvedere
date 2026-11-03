#!/bin/sh
# Real-window pixel regression for detached door-frame outlines.
set -eu
cd "$(dirname "$0")/.."
exec godot --path . --script res://tests/door_render_tests.gd -- --shots="${1:-res://screenshots/door-fix}"
