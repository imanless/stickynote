# Architecture

StickyNote is a Swift package with two modules. Its one dependency is
[Sparkle](https://sparkle-project.org), which installs updates.

```
Sources/
  StickyNoteCore/        Model and storage. Foundation only, no UI, fully unit tested.
    Notes/               Note, NoteColor, FontOverride, NoteFrame, TextStyle, StyleRun, FontRun
    Storage/             NoteStore: reads and writes notes.json
    Settings/            FontSettings, NewNoteDefaults, and the KeyValueStore they are saved to
  StickyNote/            The macOS app (AppKit, with SwiftUI for small views)
    App/                 Entry point, app delegate, menu bar, updater
    Notes/               One window per note, the controller that owns them all, Add to Notes
    Formatting/          Rich text: styles and fonts of words, the note text view, Font and Size menus
    Settings/            Settings window and app-wide preferences
Tests/
  StickyNoteCoreTests/   Model and storage tests
  StickyNoteTests/       Rich text tests, run against real text views
Support/                 Info.plist and app icon
scripts/                 Build, packaging and release helpers
```

## How the pieces fit

- **`NotesController`** owns every open note. It loads notes at launch, creates and deletes
  note windows, and saves all notes to the `NoteStore` half a second after the last change.
- **`NoteWindowController`** manages one note's window: its text view, color, font, and Keep
  on Top window level. Add to Notes hands the note's text to the share extension of Apple's
  Notes app (`AppleNotes`), which needs no permission. Edits flow into its **`NoteModel`**,
  which reports them back to `NotesController` so they get saved.
- **`RichText`** converts between what the text view displays and what is stored: plain text
  plus a list of `StyleRun`s (for example "bold from character 0, length 5") and `FontRun`s
  (for example "24 pt from character 0, length 5"). A font run stores only what was chosen for
  that text and follows the note's font for the rest, so changing the font in Settings or in a
  note's palette simply redraws the note. `NoteTextView` also copies text in this form, so
  pasting it into another note keeps its fonts.
- **`AppSettings`** holds preferences. `NotesController` reads them when creating a note, and
  is told when the font changes so it can redraw open notes.
- **`AppUpdater`** wraps Sparkle. It reads the update feed published with each release (see
  [RELEASING.md](RELEASING.md)) and offers new versions to the user.

## The notes file

Notes are stored as readable JSON in `~/Library/Application Support/StickyNote/notes.json`:

```json
{
  "version" : 1,
  "notes" : [
    {
      "id" : "…",
      "text" : "Shopping list\nmilk",
      "styles" : [{ "style" : "bold", "location" : 0, "length" : 13 }],
      "fontRuns" : [{ "font" : { "size" : 24 }, "location" : 0, "length" : 13 }],
      "color" : "yellow",
      "font" : { "size" : 18 },
      "isPinned" : true,
      "frame" : { "x" : 300, "y" : 300, "width" : 260, "height" : 240 },
      "createdAt" : "2026-10-16T08:00:00Z",
      "modifiedAt" : "2026-10-16T08:00:00Z"
    }
  ]
}
```

Users' notes must never be lost, so changes to this format follow these rules:

- **Adding a field** needs no version change. Decode it with `decodeIfPresent` and a default, as
  `Note` does for `styles`, so files from older versions still load.
- **Adding a case** to an enum such as `NoteColor` or `TextStyle` needs no version change; older
  versions already fall back or skip values they don't know.
- **Renaming, removing or changing the meaning of a field** requires increasing
  `NoteStore.currentVersion` and migrating older files when loading. Older app versions will
  then refuse the file instead of misreading it.
- If a file can't be read, `NoteStore` moves it aside rather than overwriting it. Keep it that way.

## Common changes

**A new note property** (say, a per-note opacity): add it to `Note` (with `decodeIfPresent`),
`NoteModel`, and `NoteModel.note`; apply it in `NoteWindowController`; add a test in
`NoteStoreTests` that the property survives saving and loading.

**A new text style** (say, highlight): add a case to `TextStyle`; describe how it looks in
`RichText.attributes(for:)` and how to recognize it in `RichText.styles(in:)`; give it a name
in `TextStyle+Menu.swift`. It then appears in the Format menu and the right-click menu
automatically. Add a round-trip test in `RichTextTests`.

**A new setting**: add a value type with `init(store:)` and `save(to:)` in
`StickyNoteCore/Settings` (see `FontSettings`), a property on `AppSettings`, a control in
`SettingsView`, and use it in `NotesController`: read it when needed, as `createNote()` does
with `newNotes`, or add a callback like `onFontChange` if open notes must update at once.

**A new menu command**: add the item in `MainMenu`. Commands that act on one note should be an
`@objc` method on `NoteWindowController`, reached through the responder chain.
