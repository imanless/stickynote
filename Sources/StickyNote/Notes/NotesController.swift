import AppKit
import OSLog
import StickyNoteCore

/// Keeps track of every open note and keeps the notes file in sync with them.
@MainActor
final class NotesController: NoteWindowControllerDelegate {
    private static let defaultNoteSize = NSSize(width: 260, height: 240)
    /// How far each new note is offset from the frontmost one, so they don't stack exactly.
    private static let cascadeOffset: CGFloat = 24
    /// Saving waits for a pause in typing instead of writing the file on every keystroke.
    private static let saveDelay: Duration = .milliseconds(500)

    private let store: NoteStore
    private let settings: AppSettings
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "StickyNote",
        category: "Notes"
    )
    private var windowControllers: [NoteWindowController] = []
    private var pendingSave: Task<Void, Never>?
    /// Turned off if an existing notes file could neither be read nor moved aside,
    /// so that it is never overwritten.
    private var isSavingEnabled = true
    private var hasReportedSaveFailure = false

    init(store: NoteStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
        settings.onFontChange = { [weak self] in self?.fontDidChange() }
    }

    private var richText: RichText {
        RichText(font: settings.font.nsFont)
    }

    var hasNotes: Bool {
        !windowControllers.isEmpty
    }

    /// Reopens the notes saved last time, or starts a first, empty note.
    func restoreNotes() {
        let notes: [Note]
        do {
            notes = try store.load()
        } catch {
            notes = []
            recoverFromUnreadableFile(error)
        }

        for note in notes {
            open(NoteModel(note: note))
        }
        if notes.isEmpty {
            createNote()
        }
    }

    func createNote() {
        let note = Note(frame: NoteFrame(frameForNewNote()), isPinned: settings.newNotes.isPinned)
        open(NoteModel(note: note))
        scheduleSave()
    }

    // MARK: - NoteWindowControllerDelegate

    func noteWindowControllerDidChangeNote(_ controller: NoteWindowController) {
        scheduleSave()
    }

    func noteWindowControllerDidDeleteNote(_ controller: NoteWindowController) {
        windowControllers.removeAll { $0 === controller }
        scheduleSave()
    }

    // MARK: - Saving

    func scheduleSave() {
        pendingSave?.cancel()
        pendingSave = Task { [weak self] in
            try? await Task.sleep(for: Self.saveDelay)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    func saveNow() {
        pendingSave?.cancel()
        pendingSave = nil
        guard isSavingEnabled else { return }

        do {
            try store.save(windowControllers.map(\.model.note))
        } catch {
            logger.error("Saving notes failed: \(error.localizedDescription, privacy: .public)")
            reportSaveFailure(error)
        }
    }

    // MARK: - Private

    private func fontDidChange() {
        let richText = richText
        for controller in windowControllers {
            controller.richText = richText
        }
    }

    private func open(_ model: NoteModel) {
        let controller = NoteWindowController(model: model, richText: richText)
        controller.delegate = self
        windowControllers.append(controller)
        controller.showWindow(nil)
    }

    private func frameForNewNote() -> NSRect {
        let size = Self.defaultNoteSize
        let frontmost =
            NSApp.keyWindow?.windowController as? NoteWindowController ?? windowControllers.last

        if let anchor = frontmost?.window?.frame {
            return NSRect(
                x: anchor.minX + Self.cascadeOffset,
                y: anchor.maxY - Self.cascadeOffset - size.height,
                width: size.width,
                height: size.height
            )
        }

        let screen = NSScreen.main?.visibleFrame ?? NSRect(origin: .zero, size: size)
        return NSRect(
            x: screen.midX - size.width / 2,
            y: screen.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    private func recoverFromUnreadableFile(_ loadError: any Error) {
        logger.error("Loading notes failed: \(loadError.localizedDescription, privacy: .public)")

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Your notes couldn’t be opened"
        do {
            let backupURL = try store.moveAside()
            alert.informativeText = """
                \(loadError.localizedDescription)

                The file was kept, unchanged, at:
                \(backupURL.path)

                StickyNote will start with a new note.
                """
        } catch {
            isSavingEnabled = false
            alert.informativeText = """
                \(loadError.localizedDescription)

                To protect the existing file at \(store.fileURL.path), \
                changes won’t be saved until StickyNote is restarted.
                """
        }
        alert.runModal()
    }

    private func reportSaveFailure(_ error: any Error) {
        // Saving is retried after every edit; only interrupt the user the first time.
        guard !hasReportedSaveFailure else { return }
        hasReportedSaveFailure = true

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Your notes couldn’t be saved"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}
