#!/usr/bin/env bash
# Builds build/StickyNote.app, a universal app for Apple silicon and Intel Macs.
#
# Optional environment variables:
#   VERSION           Version to stamp into the app, e.g. 1.2.0 (default: the one in Support/Info.plist)
#   SIGNING_IDENTITY  A "Developer ID Application" certificate in the keychain. Without it the app
#                     gets an ad-hoc signature, which runs locally but isn't trusted by Gatekeeper.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="StickyNote"
APP_BUNDLE="build/$APP_NAME.app"
SPARKLE="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
PLIST_BUDDY="/usr/libexec/PlistBuddy"
SWIFT_BUILD=(swift build --configuration release --arch arm64 --arch x86_64)

VERSION="${VERSION:-$("$PLIST_BUDDY" -c "Print :CFBundleShortVersionString" Support/Info.plist)}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "error: VERSION must look like 1.2.3, got '$VERSION'" >&2
    exit 1
fi

sign() {
    if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
        codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$@"
    else
        codesign --force --sign - "$@"
    fi
}

echo "==> Building $APP_NAME $VERSION"
"${SWIFT_BUILD[@]}"
BIN_DIR="$("${SWIFT_BUILD[@]}" --show-bin-path)"

echo "==> Assembling $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$APP_BUNDLE/Contents/Frameworks"
cp "$BIN_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp Support/Info.plist "$APP_BUNDLE/Contents/Info.plist"
cp Support/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
# Sparkle compares CFBundleVersion to find newer releases, so it is the version too.
"$PLIST_BUDDY" \
    -c "Set :CFBundleShortVersionString $VERSION" \
    -c "Set :CFBundleVersion $VERSION" \
    "$APP_BUNDLE/Contents/Info.plist"

ditto "$BIN_DIR/Sparkle.framework" "$SPARKLE"
# Sparkle's XPC services are only needed by sandboxed apps.
rm -rf "$SPARKLE/XPCServices" "$SPARKLE/Versions/B/XPCServices"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
    echo "==> Signing with Developer ID"
else
    echo "==> Signing ad-hoc (no SIGNING_IDENTITY set)"
fi
# Nested code must be signed before the code that contains it.
sign "$SPARKLE/Versions/B/Autoupdate"
sign "$SPARKLE/Versions/B/Updater.app"
sign "$SPARKLE"
sign "$APP_BUNDLE"
codesign --verify --strict --deep "$APP_BUNDLE"

echo "==> Done: $APP_BUNDLE"
