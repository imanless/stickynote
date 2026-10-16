#!/usr/bin/env bash
# Builds StickyNote.app, a double-clickable macOS app, into ./build.
# The app is "universal": it runs natively on both Apple silicon and Intel Macs.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="StickyNote"
CONFIGURATION="${CONFIGURATION:-release}"
APP_BUNDLE="build/$APP_NAME.app"
SWIFT_BUILD=(swift build --configuration "$CONFIGURATION" --arch arm64 --arch x86_64)

echo "==> Building $APP_NAME ($CONFIGURATION)"
"${SWIFT_BUILD[@]}"
BIN_DIR="$("${SWIFT_BUILD[@]}" --show-bin-path)"

echo "==> Assembling $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp Support/Info.plist "$APP_BUNDLE/Contents/Info.plist"

# An ad-hoc signature lets the app run on this Mac. Sharing a ready-made app with
# others additionally needs a Developer ID signature and Apple notarization.
codesign --force --sign - "$APP_BUNDLE"

echo "==> Done: $APP_BUNDLE"
