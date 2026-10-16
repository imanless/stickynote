# StickyNote

Sticky notes for macOS that can stay on top of other windows.

- Notes stay above all other apps, on every desktop, including over full-screen apps. New notes
  start out pinned; unpin one with its pin button or ⇧⌘P, or change the default in Settings.
- Bold, italic, underline and strikethrough from the right-click menu or ⌘B / ⌘I / ⌘U.
- Six note colors, and a font and text size for each note, from the note's palette button.
- Set the default font and size, and whether new notes are pinned, in Settings (⌘,).
- Notes save as you type and reopen where you left them.

The app only goes online to check for a newer version, about once a day, and only if you allow
it.

## Installing

Requires macOS 14 or later.

1. Download the `.dmg` file from the [latest release](https://github.com/imanless/stickynote/releases/latest).
2. Open it and drag StickyNote into Applications.
3. Open StickyNote.

The app isn't notarized by Apple yet, so the first time you open it macOS says it can't verify
it. Click Done, then go to System Settings → Privacy & Security, scroll down, and click
Open Anyway next to StickyNote. You only need to do this once.

StickyNote updates itself: when a new version is out, it shows what changed and installs it
with one click. To check right away, choose StickyNote → Check for Updates…. Versions before
0.3.0 can't do this; replace those once by downloading the new `.dmg`. Your notes are kept.

To check that a download is genuine, see [Verifying downloads](SECURITY.md#verifying-downloads).

## Keyboard shortcuts

| Action                    | Shortcut     |
| ------------------------- | ------------ |
| New note                  | ⌘N           |
| Keep on top               | ⇧⌘P          |
| Bold / Italic / Underline | ⌘B / ⌘I / ⌘U |
| Bigger / smaller text     | ⌘+ / ⌘-      |
| Note color                | ⌘1 – ⌘6      |
| Settings                  | ⌘,           |
| Delete note               | ⌘W           |

## Your notes

Notes are stored in `~/Library/Application Support/StickyNote/notes.json`. To store them
somewhere else, for example a synced folder:

```sh
defaults write io.github.imanless.StickyNote NotesFilePath ~/Dropbox/StickyNote/notes.json
```

To uninstall, delete StickyNote from Applications. To also remove your notes and settings:

```sh
rm -rf ~/Library/Application\ Support/StickyNote
defaults delete io.github.imanless.StickyNote
```

## Building from source

Requires Xcode 26 or later. Older versions down to Xcode 16.3 also build it, but the app then
uses the look from before macOS 26.

```sh
git clone https://github.com/imanless/stickynote.git
cd stickynote
make install
```

This builds the app and copies it to Applications. `make help` lists the other commands. See
[CONTRIBUTING.md](CONTRIBUTING.md) if you'd like to make changes.

## License

[MIT](LICENSE)
