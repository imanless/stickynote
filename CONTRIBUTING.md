# Contributing

How to set up the project, make a change, and get it merged.

## Setting up

You need macOS 14 or later and Xcode 16.3 or later. There are no other dependencies.

```sh
git clone https://github.com/imanless/stickynote.git
cd stickynote
make test   # run the tests
make run    # run the app from the terminal
```

`make help` lists every command. To try changes without touching your real notes, run the app
with a separate notes file:

```sh
swift run StickyNote -NotesFilePath /tmp/test-notes.json
```

You can also open `Package.swift` in Xcode.

## Making a change

1. For anything bigger than a small fix, open an issue first to agree on the approach.
2. Create a branch from `main`.
3. Make your change, with tests for anything in `StickyNoteCore` and the formatting code.
4. Run `make format`, then `make lint test` and make sure both pass.
5. Add a line under **Unreleased** in [CHANGELOG.md](CHANGELOG.md) if users will notice the change.
6. Open a pull request. CI must pass before it can be merged.

## Code guidelines

- Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) to see where things belong.
- Keep logic that doesn't need AppKit in `StickyNoteCore`, where it can be unit tested.
- The project builds in Swift 6 language mode with strict concurrency checking; keep it free of
  warnings.
- Formatting is enforced by `swift format` using [.swift-format](.swift-format).
- Write comments that explain *why* something is done when it isn't obvious; don't restate
  what the code says.
- Don't add third-party dependencies without discussing it in an issue first.

## Releasing

Maintainers: see [docs/RELEASING.md](docs/RELEASING.md).
