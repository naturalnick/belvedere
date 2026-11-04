#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
exec swift tools/gen_qr.swift "$@"
