#!/usr/bin/env bash
# Builds build/StickyNote.app, a universal app for Apple silicon and Intel Macs.
#
# Optional environment variables:
#   VERSION           Version to stamp into the app, e.g. 1.2.0 (default: the one in Support/Info.plist)
#   BUILD_NUMBER      Build number to stamp into the app (default: 1)
#   SIGNING_IDENTITY  A "Developer ID Application" certificate in the keychain. Without it the app
#                     gets an ad-hoc signature, which runs locally but isn't trusted by Gatekeeper.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="StickyNote"
APP_BUNDLE="build/$APP_NAME.app"
PLIST_BUDDY="/usr/libexec/PlistBuddy"
SWIFT_BUILD=(swift build --configuration release --arch arm64 --arch x86_64)

VERSION="${VERSION:-$("$PLIST_BUDDY" -c "Print :CFBundleShortVersionString" Support/Info.plist)}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "error: VERSION must look like 1.2.3, got '$VERSION'" >&2
    exit 1
fi

echo "==> Building $APP_NAME $VERSION ($BUILD_NUMBER)"
"${SWIFT_BUILD[@]}"
BIN_DIR="$("${SWIFT_BUILD[@]}" --show-bin-path)"

echo "==> Assembling $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp Support/Info.plist "$APP_BUNDLE/Contents/Info.plist"
cp Support/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
"$PLIST_BUDDY" \
    -c "Set :CFBundleShortVersionString $VERSION" \
    -c "Set :CFBundleVersion $BUILD_NUMBER" \
    "$APP_BUNDLE/Contents/Info.plist"

if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
    echo "==> Signing with Developer ID"
    codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"
else
    echo "==> Signing ad-hoc (no SIGNING_IDENTITY set)"
    codesign --force --sign - "$APP_BUNDLE"
fi
codesign --verify --strict "$APP_BUNDLE"

echo "==> Done: $APP_BUNDLE"
