import Foundation
import StickyNoteCore
import Testing

struct StyleRunTests {
    @Test func overlappingAndTouchingRunsOfOneStyleAreMerged() {
        let runs = [
            StyleRun(style: .bold, location: 0, length: 4),
            StyleRun(style: .bold, location: 2, length: 4),  // overlaps
            StyleRun(style: .bold, location: 6, length: 2),  // touches
        ]
        #expect(StyleRun.normalized(runs, textLength: 20) == [StyleRun(style: .bold, location: 0, length: 8)])
    }

    @Test func runsOfDifferentStylesStaySeparate() {
        let runs = [
            StyleRun(style: .italic, location: 0, length: 5),
            StyleRun(style: .bold, location: 0, length: 5),
        ]
        #expect(
            StyleRun.normalized(runs, textLength: 5) == [
                StyleRun(style: .bold, location: 0, length: 5),
                StyleRun(style: .italic, location: 0, length: 5),
            ]
        )
    }

    @Test func separatedRunsAreNotMerged() {
        let runs = [
            StyleRun(style: .underline, location: 6, length: 2),
            StyleRun(style: .underline, location: 0, length: 2),
        ]
        #expect(
            StyleRun.normalized(runs, textLength: 10) == [
                StyleRun(style: .underline, location: 0, length: 2),
                StyleRun(style: .underline, location: 6, length: 2),
            ]
        )
    }

    @Test func runsAreClampedToTheText() {
        let runs = [
            StyleRun(style: .bold, location: 3, length: 100),
            StyleRun(style: .italic, location: -5, length: 2),
        ]
        #expect(
            StyleRun.normalized(runs, textLength: 5) == [
                StyleRun(style: .bold, location: 3, length: 2),
                StyleRun(style: .italic, location: 0, length: 2),
            ]
        )
    }

    @Test func emptyAndOutOfRangeRunsAreDropped() {
        let runs = [
            StyleRun(style: .bold, location: 2, length: 0),
            StyleRun(style: .italic, location: 10, length: 3),
            StyleRun(style: .underline, location: 1, length: -4),
        ]
        #expect(StyleRun.normalized(runs, textLength: 5).isEmpty)
    }
}

struct NoteDecodingTests {
    private func decodeNote(styles stylesJSON: String?) throws -> Note {
        let stylesField = stylesJSON.map { #""styles": \#($0),"# } ?? ""
        let json = """
            {
              "id": "11111111-1111-1111-1111-111111111111",
              "text": "Hello world",
              \(stylesField)
              "color": "yellow",
              "frame": {"x": 0, "y": 0, "width": 200, "height": 200},
              "isPinned": false,
              "createdAt": "2026-10-16T08:00:00Z",
              "modifiedAt": "2026-10-16T08:00:00Z"
            }
            """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Note.self, from: Data(json.utf8))
    }

    @Test func noteSavedBeforeFormattingExistedHasNoStyles() throws {
        let note = try decodeNote(styles: nil)
        #expect(note.text == "Hello world")
        #expect(note.styles.isEmpty)
    }

    @Test func unknownStylesAreSkippedAndKnownOnesKept() throws {
        let note = try decodeNote(
            styles: """
                [
                  {"style": "bold", "location": 0, "length": 5},
                  {"style": "sparkles", "location": 6, "length": 5}
                ]
                """
        )
        #expect(note.styles == [StyleRun(style: .bold, location: 0, length: 5)])
    }
}
