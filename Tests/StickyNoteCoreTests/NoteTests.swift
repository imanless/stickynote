import Foundation
import StickyNoteCore
import Testing

struct NoteTests {
    private let frame = NoteFrame(x: 0, y: 0, width: 200, height: 200)

    @Test func titleIsFirstNonEmptyLineTrimmed() {
        let note = Note(text: "\n   \n  Groceries  \nmilk\neggs", frame: frame)
        #expect(note.title == "Groceries")
    }

    @Test func titleIsEmptyForBlankNote() {
        #expect(Note(text: " \n\t ", frame: frame).title == "")
    }

    @Test func titleAtMaximumLengthIsKept() {
        let text = String(repeating: "a", count: Note.maxTitleLength)
        #expect(Note(text: text, frame: frame).title == text)
    }

    @Test func longTitleIsShortenedWithEllipsis() {
        let title = Note(text: String(repeating: "a", count: 100), frame: frame).title
        #expect(title.count == Note.maxTitleLength)
        #expect(title.hasSuffix("…"))
    }

    @Test(arguments: ["", "   ", "\n\t \n"])
    func whitespaceOnlyNoteIsBlank(text: String) {
        #expect(Note(text: text, frame: frame).isBlank)
    }

    @Test func noteWithTextIsNotBlank() {
        #expect(!Note(text: "  hello ", frame: frame).isBlank)
    }

    @Test func newNoteHasDefaults() {
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let note = Note(frame: frame, createdAt: createdAt)
        #expect(note.text.isEmpty)
        #expect(note.color == .yellow)
        #expect(!note.isPinned)
        #expect(note.modifiedAt == createdAt)
    }
}

struct NoteColorTests {
    @Test func unknownColorFallsBackToYellow() throws {
        let json = Data(#"["pink", "a-color-from-the-future"]"#.utf8)
        let colors = try JSONDecoder().decode([NoteColor].self, from: json)
        #expect(colors == [.pink, .yellow])
    }
}

struct NoteFrameTests {
    private let laptopScreen = NoteFrame(x: 0, y: 0, width: 1440, height: 900)
    private let externalScreen = NoteFrame(x: 1440, y: 0, width: 2560, height: 1440)

    @Test func frameOnScreenIsReachable() {
        let frame = NoteFrame(x: 100, y: 100, width: 260, height: 240)
        #expect(frame.isReachable(on: [laptopScreen]))
    }

    @Test func frameOnSecondScreenIsReachable() {
        let frame = NoteFrame(x: 2000, y: 500, width: 260, height: 240)
        #expect(frame.isReachable(on: [laptopScreen, externalScreen]))
    }

    @Test func frameOnDisconnectedScreenIsNotReachable() {
        let frame = NoteFrame(x: 2000, y: 500, width: 260, height: 240)
        #expect(!frame.isReachable(on: [laptopScreen]))
    }

    @Test func frameWithOnlyASliverOnScreenIsNotReachable() {
        let frame = NoteFrame(x: 1420, y: 100, width: 260, height: 240)
        #expect(!frame.isReachable(on: [laptopScreen]))
    }

    @Test func noScreensMeansNotReachable() {
        #expect(!NoteFrame(x: 0, y: 0, width: 100, height: 100).isReachable(on: []))
    }
}
