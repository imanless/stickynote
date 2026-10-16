import Foundation
import StickyNoteCore
import Testing

/// Each test gets a fresh instance, and so its own temporary directory.
final class NoteStoreTests {
    private let directory: URL
    private let store: NoteStore

    init() {
        directory = FileManager.default.temporaryDirectory
            .appending(component: "StickyNoteTests-\(UUID().uuidString)")
        // A nested path, to check that saving creates missing directories.
        store = NoteStore(fileURL: directory.appending(components: "StickyNote", "notes.json"))
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func loadingBeforeAnythingIsSavedReturnsNoNotes() throws {
        #expect(try store.load().isEmpty)
    }

    @Test func savedNotesLoadBackUnchanged() throws {
        // Whole seconds, because dates are stored as ISO 8601 without fractions.
        let notes = [
            Note(
                text: "Buy milk\nCall mom",
                styles: [
                    StyleRun(style: .bold, location: 0, length: 8),
                    StyleRun(style: .strikethrough, location: 9, length: 8),
                ],
                color: .pink,
                font: FontOverride(family: "Menlo", size: 18),
                frame: NoteFrame(x: 10, y: 20, width: 300, height: 250),
                isPinned: true,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                modifiedAt: Date(timeIntervalSince1970: 1_700_000_500)
            ),
            Note(
                frame: NoteFrame(x: 400, y: 20, width: 260, height: 240),
                createdAt: Date(timeIntervalSince1970: 1_700_001_000)
            ),
        ]

        try store.save(notes)

        #expect(try store.load() == notes)
    }

    @Test func savingReplacesPreviousNotes() throws {
        let frame = NoteFrame(x: 0, y: 0, width: 100, height: 100)
        try store.save([Note(text: "old", frame: frame), Note(text: "older", frame: frame)])

        try store.save([Note(text: "new", frame: frame)])

        #expect(try store.load().map(\.text) == ["new"])
    }

    @Test func savedFileRecordsFormatVersion() throws {
        try store.save([])

        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: store.fileURL))
        #expect((json as? [String: Any])?["version"] as? Int == NoteStore.currentVersion)
    }

    @Test func damagedFileIsReportedAsCorrupted() throws {
        try writeNotesFile("this is not JSON")

        let error = #expect(throws: NoteStoreError.self) { try store.load() }

        guard case .corrupted = error else {
            Issue.record("Expected .corrupted, got \(String(describing: error))")
            return
        }
    }

    @Test func fileFromNewerVersionIsReportedAsUnsupported() throws {
        try writeNotesFile(#"{"version": 99, "notes": {"format": "changed"}}"#)

        let error = #expect(throws: NoteStoreError.self) { try store.load() }

        guard case .unsupportedVersion(99) = error else {
            Issue.record("Expected .unsupportedVersion(99), got \(String(describing: error))")
            return
        }
    }

    @Test func movingAsideKeepsTheFileAndFreesItsName() throws {
        try writeNotesFile("damaged contents")

        let backupURL = try store.moveAside()

        #expect(backupURL.lastPathComponent.hasPrefix("notes.unreadable-"))
        #expect(backupURL.pathExtension == "json")
        #expect(try String(contentsOf: backupURL, encoding: .utf8) == "damaged contents")
        #expect(try store.load().isEmpty)
    }

    private func writeNotesFile(_ contents: String) throws {
        try FileManager.default.createDirectory(
            at: store.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: store.fileURL)
    }
}
