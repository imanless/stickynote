# Releasing

Releases are built and published by the [Release workflow](../.github/workflows/release.yml)
when a version tag is pushed.

## Publishing a release

1. Pick the version, following [Semantic Versioning](https://semver.org/): increase the third
   number for fixes, the second for new features, the first for breaking changes.
2. In [CHANGELOG.md](../CHANGELOG.md), rename **Unreleased** to the new version and date, add a
   new empty **Unreleased** section above it, and update the links at the bottom. Set the same
   version as `CFBundleShortVersionString` in [Support/Info.plist](../Support/Info.plist), so
   local builds show it too.
3. Merge that change into `main` through a pull request.
4. Tag the merged commit and push the tag:

   ```sh
   git switch main && git pull
   git tag v1.2.0
   git push origin v1.2.0
   ```

The workflow then runs the tests, builds a universal `StickyNote.app` stamped with the version,
packages it as `StickyNote-1.2.0.dmg`, records a signed build attestation, and publishes a
GitHub release whose notes are the changelog entry. It fails without publishing anything if the
changelog has no entry for the version.

To try packaging locally first: `VERSION=1.2.0 make dmg`.

## Signing and notarization (optional)

Without the secrets below, releases are signed ad hoc and users approve the app once in
System Settings the first time they open it. With them, the app is signed with a Developer ID
and notarized by Apple, so it opens without any warning.

This needs a paid [Apple Developer Program](https://developer.apple.com/programs/) membership.
Note that a Developer ID signature includes the name on your Apple developer account, and
anyone can read it from the app.

1. In your Apple developer account, create a **Developer ID Application** certificate. Export
   it from Keychain Access as a `.p12` file with a strong password.
2. In [App Store Connect → Users and Access → Integrations](https://appstoreconnect.apple.com/access/integrations/api),
   create a Team API key with the **Developer** role and download the `.p8` file. Note its
   Key ID and the Issuer ID.
3. In the GitHub repository, open **Settings → Environments → release** and add these
   environment secrets (environment secrets are only available to the release workflow):

   | Secret                         | Value                                     |
   | ------------------------------ | ----------------------------------------- |
   | `MACOS_CERTIFICATE_P12_BASE64` | Output of `base64 -i certificate.p12`     |
   | `MACOS_CERTIFICATE_PASSWORD`   | The `.p12` password                       |
   | `NOTARY_API_KEY_P8_BASE64`     | Output of `base64 -i AuthKey_XXXXXXXX.p8` |
   | `NOTARY_API_KEY_ID`            | The API key's Key ID                      |
   | `NOTARY_API_ISSUER_ID`         | The Issuer ID                             |

4. Delete the local `.p12` and `.p8` files, or keep them only in a password manager. Never
   commit them; `.gitignore` blocks the common signing file types as a safeguard.

The next release will be signed and notarized. Afterwards, remove the "isn't notarized"
instructions from the README's **Installing** section.
