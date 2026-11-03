#!/bin/sh
# Offline audio preparation; the game itself needs only the committed assets.
set -eu
cd "$(dirname "$0")/.."
command -v ffmpeg >/dev/null; command -v oggenc >/dev/null
# The venv contains scipy test WAVs that Godot would otherwise try to import.
mkdir -p build && touch build/.gdignore
if [ ! -x build/audio-tools/bin/python ]; then python3 -m venv build/audio-tools; fi
build/audio-tools/bin/pip -q install -r tools/audio-requirements.txt
exec build/audio-tools/bin/python tools/gen_audio.py "$@"
