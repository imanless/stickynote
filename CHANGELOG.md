# Changelog

All notable changes to StickyNote are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.5.1] - 2026-10-16

### Fixed

- Released copies now use the current macOS look on macOS 26, for example in the Font and Size
  menus. They were built with an older Xcode than local builds.

## [0.5.0] - 2026-10-16

### Added

- Each note can have its own font and text size. Click the note's palette button and choose
  them below the colors; "Default" follows the font and size set in Settings.
- Note → Bigger (⌘+) and Smaller (⌘-) change the text size of the current note.

## [0.4.0] - 2026-10-16

### Changed

- The palette button now shows the note colors themselves instead of a list of their names.
  Click a color to use it; the current one has a checkmark.

## [0.3.0] - 2026-10-16

### Added

- StickyNote now updates itself. It checks for new versions about once a day, after asking
  permission, and installs them in place. Use StickyNote → Check for Updates… to check at any
  time, or turn automatic checks off in Settings. Earlier versions have to be updated by
  downloading this one manually.

## [0.2.0] - 2026-10-16

### Changed

- New notes are kept on top of other windows by default. Turn this off in Settings with
  "Keep new notes on top".

## [0.1.0] - 2026-10-16

### Added

- Keep on Top: pin a note above all other windows, on every desktop and over full-screen apps.
- Bold, italic, underline and strikethrough from the right-click menu, the Format menu, or ⌘B / ⌘I / ⌘U.
- Settings window (⌘,) to choose the font and text size for all notes.
- Six note colors.
- Notes save automatically and reopen where you left them.

[Unreleased]: https://github.com/imanless/stickynote/compare/v0.5.1...HEAD
[0.5.1]: https://github.com/imanless/stickynote/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/imanless/stickynote/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/imanless/stickynote/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/imanless/stickynote/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/imanless/stickynote/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/imanless/stickynote/releases/tag/v0.1.0
