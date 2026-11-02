#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
godot --headless --import --path .
exec godot --path . -- "$@"
