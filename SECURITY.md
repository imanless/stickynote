# Security

## Reporting a vulnerability

Please report security issues privately through
[GitHub's private vulnerability reporting](https://github.com/imanless/stickynote/security/advisories/new),
not in a public issue. You'll get a reply as soon as possible, and fixes are released for the
latest version.

## What StickyNote accesses

StickyNote collects no data. It reads and writes only:

- its notes file, `~/Library/Application Support/StickyNote/notes.json` (or the path set with
  `NotesFilePath`), and
- its own preferences (`io.github.imanless.StickyNote`).

Its only network connection is the update check, made with
[Sparkle](https://sparkle-project.org): about once a day, if the user allows it, it downloads
`https://github.com/imanless/stickynote/releases/latest/download/appcast.xml`. No information
about the Mac or its user is sent beyond what any download from GitHub includes.

## Update signing

Updates are signed with a private key that only the release workflow can use. The app contains
the matching public key and accepts an update only when both the list of versions (the feed)
and the downloaded file carry valid signatures from that key, so a modified or substituted
download is refused. Each release is checked against the app's public key before it is
published.

## Verifying downloads

Every release is built from this repository by GitHub Actions. You can check that a disk image
you downloaded is the one that workflow produced.

Compare its checksum with the `.sha256` file published next to it:

```sh
shasum -a 256 -c StickyNote-0.1.0.dmg.sha256
```

Or verify GitHub's signed build attestation, which also proves which commit it was built from
(requires the [GitHub CLI](https://cli.github.com)):

```sh
gh attestation verify StickyNote-0.1.0.dmg --repo imanless/stickynote
```
