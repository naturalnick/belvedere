#!/bin/sh
# Upload only on Nick's request; the archives must match the supplied build revision.
set -eu
cd "$(dirname "$0")/.."
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <built-revision> [all|html5|macos|windows]" >&2
    exit 1
fi
BUILD_REVISION="$1"
case "${2:-all}" in
    all) CHANNELS="html5 macos windows" ;;
    html5|macos|windows) CHANNELS="$2" ;;
    *) echo "Unknown channel: $2" >&2; exit 1 ;;
esac
archive_for() {
    case "$1" in
        html5) echo build/itch/belvedere-web.zip ;;
        macos) echo build/macos/belvedere-macos.zip ;;
        windows) echo build/windows/belvedere-windows.zip ;;
    esac
}
command -v butler >/dev/null
python3 tools/check_export_identity.py
for channel in $CHANNELS; do
    archive="$(archive_for "$channel")"
    if [ ! -s "$archive" ]; then
        echo "Missing build: $archive" >&2
        exit 1
    fi
done
for channel in $CHANNELS; do
    butler push "$(archive_for "$channel")" "puzzaholics/belvedere:$channel" --userversion "$BUILD_REVISION"
done
butler status puzzaholics/belvedere
