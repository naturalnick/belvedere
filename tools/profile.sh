#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
exec godot --disable-render-loop --path . --script res://tools/profile_driver.gd -- --output="${1:-res://build/profile.json}"
