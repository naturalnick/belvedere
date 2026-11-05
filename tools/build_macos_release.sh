#!/bin/sh
# Signs and notarizes with Apple, then stops at a local zip. No upload to itch or anywhere else.
set -eu
cd "$(dirname "$0")/.."
python3 tools/check_export_identity.py
TEAM="$(python3 -c "import json; print(json.load(open('apple-identity.json'))['team_id'])")"
BUNDLE_ID="$(python3 -c "import json; print(json.load(open('apple-identity.json'))['bundle_identifier'])")"
IDENTITY="$(python3 -c "import json; print(json.load(open('apple-identity.json'))['release_preset']['identity'])")"
PROFILE="belvedere-notary"

if ! security find-identity -v -p codesigning | grep -qF "\"$IDENTITY\""; then
    echo "Missing signing identity: $IDENTITY" >&2
    echo "Xcode > Settings > Accounts > Puzzaholics LLC > Manage Certificates > + > Developer ID Application" >&2
    exit 1
fi
if ! xcrun notarytool history --keychain-profile "$PROFILE" > /dev/null 2>&1; then
    echo "Missing or invalid notary profile: $PROFILE" >&2
    echo "xcrun notarytool store-credentials $PROFILE --team-id $TEAM --apple-id <Apple ID>" >&2
    exit 1
fi

mkdir -p build/macos
STAGING="$(mktemp -d "$(pwd)/build/macos/release.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT HUP INT TERM
APP="$STAGING/Belvedere.app"
godot --headless --path . --import
godot --headless --path . --export-release "macOS Release" "$APP"
# Godot exits 0 when a preset fails its configuration checks, so check the result instead.
test -d "$APP"

# Refuse anything Apple would attribute to another team, before it is ever submitted.
codesign --verify --deep --strict "$APP"
codesign -dv "$APP" 2>&1 | grep -qxF "TeamIdentifier=$TEAM"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")" = "$BUNDLE_ID"

ditto -c -k --keepParent "$APP" "$STAGING/submit.zip"
xcrun notarytool submit "$STAGING/submit.zip" --keychain-profile "$PROFILE" --wait
# Stapling fails unless Apple accepted this exact build, so a rejected submission stops here.
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose "$APP"

OUTPUT="$(pwd)/build/macos/belvedere-macos.zip"
rm -f "$OUTPUT"
ditto -c -k --keepParent "$APP" "$OUTPUT"
echo "Built $OUTPUT"
