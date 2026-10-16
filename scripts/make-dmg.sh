#!/usr/bin/env bash
# Packages build/StickyNote.app into build/StickyNote-<version>.dmg, a disk image where users
# drag the app into Applications. Run scripts/build-app.sh first.
#
# Optional environment variables:
#   SIGNING_IDENTITY  Also sign the disk image with this Developer ID certificate.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="StickyNote"
APP_BUNDLE="build/$APP_NAME.app"

if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "error: $APP_BUNDLE not found; run scripts/build-app.sh first" >&2
    exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist")"
DMG="build/$APP_NAME-$VERSION.dmg"

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
cp -R "$APP_BUNDLE" "$staging/"
ln -s /Applications "$staging/Applications"

echo "==> Creating $DMG"
rm -f "$DMG"
hdiutil create -quiet -volname "$APP_NAME" -srcfolder "$staging" -fs HFS+ -format UDZO "$DMG"

if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
    codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG"
fi

echo "==> Done: $DMG"
