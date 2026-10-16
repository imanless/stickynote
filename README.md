# StickyNote

A small, native sticky notes app for macOS whose notes can be **pinned on top of every other window**.

## Features

- **Keep on Top**: pin a note with the 📌 button (or ⇧⌘P) and it floats above all other apps,
  follows you to every desktop (Space), and stays visible over full-screen apps.
- **Formatting**: right-click any text for Bold, Italic, Underline and Strikethrough.
- **Settings** (⌘,): choose the font and text size used by all notes, with a live preview.
- As many notes as you like, in six paper colors.
- Saves automatically as you type; notes reopen where you left them.
- Notes saved on a display that's no longer connected are moved back on screen.
- Native and tiny (about 1 MB): no third-party dependencies, no network access.

### Keyboard shortcuts

| Action                          | Shortcut |
| ------------------------------- | -------- |
| New note                        | ⌘N       |
| Keep on top / stop              | ⇧⌘P      |
| Bold / Italic / Underline       | ⌘B / ⌘I / ⌘U |
| Change color                    | ⌘1 – ⌘6  |
| Settings                        | ⌘,       |
| Delete note (asks if not empty) | ⌘W       |

## Requirements

- macOS 14 Sonoma or later
- To build: Xcode 16.3 or later (Swift 6.1+)

## Build and install

```sh
git clone https://github.com/imanless/stickynote.git
cd stickynote
make install      # builds StickyNote.app and copies it to /Applications
```

Or run `make app` and find the app at `build/StickyNote.app`.

## Development

```sh
make run      # build and run from the terminal
make test     # run the unit tests
make lint     # check formatting (make format fixes it)
make help     # list all commands
```

Everything is built inside this folder (`.build/` and `build/`). Nothing is installed elsewhere on
your Mac, and `make clean` removes all build output.

To experiment without touching your real notes, point the app at a different file:

```sh
swift run StickyNote -NotesFilePath /tmp/test-notes.json
```

### Project structure

```
Sources/
  StickyNoteCore/   Note model and JSON storage (no UI, unit tested)
  StickyNote/       The app: windows, menus, SwiftUI views
Tests/
  StickyNoteCoreTests/
Support/Info.plist  App bundle metadata (name, version, bundle ID)
scripts/            build-app.sh assembles StickyNote.app
```

## Where notes are stored

All notes are kept in one readable JSON file:

```
~/Library/Application Support/StickyNote/notes.json
```

To store them elsewhere, for example in a synced folder:

```sh
defaults write io.github.imanless.StickyNote NotesFilePath ~/Dropbox/StickyNote/notes.json
```

Formatting is stored next to each note's text as ranges, such as
`{"style": "bold", "location": 0, "length": 13}`, so the file stays readable.

If the file is ever damaged, StickyNote renames it to `notes.unreadable-<date>.json` instead of
overwriting it, and tells you where it is.

The font and size chosen in Settings are kept with your other macOS preferences, separately from
the notes.
