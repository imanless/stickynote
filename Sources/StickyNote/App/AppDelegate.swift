import AppKit
import StickyNoteCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Defaults key that overrides where notes are saved, e.g. for a synced folder:
    /// `defaults write io.github.imanless.StickyNote NotesFilePath ~/Dropbox/notes.json`
    /// or, for a one-off run: `swift run StickyNote -NotesFilePath /tmp/notes.json`
    static let notesFilePathKey = "NotesFilePath"

    private let settings = AppSettings()
    private let updater = AppUpdater()
    private var notesController: NotesController?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Needed when running the bare executable (`swift run`), which has no Info.plist.
        NSApp.setActivationPolicy(.regular)
        NSApp.mainMenu = MainMenu.make(appName: ProcessInfo.processInfo.processName, updater: updater)

        let controller = NotesController(store: NoteStore(fileURL: Self.notesFileURL()), settings: settings)
        notesController = controller
        controller.restoreNotes()

        NSApp.activate()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Clicking the Dock icon with every note deleted starts a fresh one.
        if notesController?.hasNotes == false {
            notesController?.createNote()
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        notesController?.saveNow()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    @objc func newNote(_ sender: Any?) {
        notesController?.createNote()
    }

    @objc func showSettings(_ sender: Any?) {
        let controller =
            settingsWindowController ?? SettingsWindowController(settings: settings, updater: updater)
        settingsWindowController = controller
        controller.showWindow(nil)
    }

    private static func notesFileURL() -> URL {
        if let path = UserDefaults.standard.string(forKey: notesFilePathKey), !path.isEmpty {
            return URL(filePath: (path as NSString).expandingTildeInPath)
        }
        return NoteStore.defaultFileURL
    }
}
