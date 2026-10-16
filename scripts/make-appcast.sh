#!/usr/bin/env bash
# Writes build/appcast.xml, the signed feed the app reads to find new versions, for the disk
# image made by scripts/make-dmg.sh. Run that first.
#
# The update signing key comes from the SPARKLE_PRIVATE_KEY environment variable (as in the
# release workflow) or, when that isn't set, from the "stickynote" item in your login keychain.
set -euo pipefail

cd "$(dirname "$0")/.."

REPOSITORY="imanless/stickynote"
APP_NAME="StickyNote"
INFO_PLIST="build/$APP_NAME.app/Contents/Info.plist"
SIGN_UPDATE=".build/artifacts/sparkle/Sparkle/bin/sign_update"
KEYCHAIN_ACCOUNT="stickynote"

plist() { /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST"; }

VERSION="$(plist CFBundleShortVersionString)"
DMG="build/$APP_NAME-$VERSION.dmg"
APPCAST="build/appcast.xml"
if [[ ! -f "$DMG" ]]; then
    echo "error: $DMG not found; run scripts/make-dmg.sh first" >&2
    exit 1
fi

sign_update() {
    if [[ -n "${SPARKLE_PRIVATE_KEY:-}" ]]; then
        printf '%s' "$SPARKLE_PRIVATE_KEY" | "$SIGN_UPDATE" --ed-key-file - "$@"
    else
        "$SIGN_UPDATE" --account "$KEYCHAIN_ACCOUNT" "$@"
    fi
}

echo "==> Signing $DMG"
enclosure_attributes="$(sign_update "$DMG")" # sparkle:edSignature="…" length="…"
signature="$(sed -E 's/.*sparkle:edSignature="([^"]+)".*/\1/' <<< "$enclosure_attributes")"
swift scripts/verify-update-signature.swift "$(plist SUPublicEDKey)" "$signature" "$DMG"

echo "==> Writing $APPCAST"
cat > "$APPCAST" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>$APP_NAME</title>
    <item>
      <title>$APP_NAME $VERSION</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$(plist CFBundleVersion)</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$(plist LSMinimumSystemVersion)</sparkle:minimumSystemVersion>
      <sparkle:fullReleaseNotesLink>https://github.com/$REPOSITORY/blob/main/CHANGELOG.md</sparkle:fullReleaseNotesLink>
      <description sparkle:format="markdown"><![CDATA[
$(scripts/changelog-section.sh "$VERSION")
]]></description>
      <enclosure url="https://github.com/$REPOSITORY/releases/download/v$VERSION/$APP_NAME-$VERSION.dmg" type="application/octet-stream" $enclosure_attributes />
    </item>
  </channel>
</rss>
EOF

# The app only accepts a signed feed (SURequireSignedFeed in Info.plist).
sign_update "$APPCAST"
sign_update --verify "$APPCAST"

echo "==> Done: $APPCAST"
