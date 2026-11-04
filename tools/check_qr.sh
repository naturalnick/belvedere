#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
exec godot --path . --script res://tests/qr_render_tests.gd
