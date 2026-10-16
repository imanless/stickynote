# Security

## Reporting a vulnerability

Please report security issues privately through
[GitHub's private vulnerability reporting](https://github.com/imanless/stickynote/security/advisories/new),
not in a public issue. You'll get a reply as soon as possible, and fixes are released for the
latest version.

## What StickyNote accesses

StickyNote makes no network connections and collects no data. It reads and writes only:

- its notes file, `~/Library/Application Support/StickyNote/notes.json` (or the path set with
  `NotesFilePath`), and
- its own preferences (`io.github.imanless.StickyNote`).

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
