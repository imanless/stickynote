import StickyNoteCore
import Testing

struct FontRunTests {
    private let menlo = FontOverride(family: "Menlo")
    private let big = FontOverride(size: 24)

    @Test func touchingAndOverlappingRunsWithTheSameFontAreMerged() {
        let runs = [
            FontRun(font: menlo, location: 4, length: 2),
            FontRun(font: menlo, location: 0, length: 4),  // touches
            FontRun(font: menlo, location: 5, length: 3),  // overlaps
        ]
        #expect(FontRun.normalized(runs, textLength: 10) == [FontRun(font: menlo, location: 0, length: 8)])
    }

    @Test func runsWithDifferentFontsStaySeparateInTextOrder() {
        let runs = [
            FontRun(font: big, location: 5, length: 3),
            FontRun(font: menlo, location: 0, length: 5),
        ]
        #expect(
            FontRun.normalized(runs, textLength: 10) == [
                FontRun(font: menlo, location: 0, length: 5),
                FontRun(font: big, location: 5, length: 3),
            ]
        )
    }

    @Test func runsThatChangeNothingAreDropped() {
        #expect(FontRun.normalized([FontRun(font: FontOverride(), location: 0, length: 5)], textLength: 10).isEmpty)
    }

    @Test func runsAreClampedToTheTextAndEmptyOnesDropped() {
        let runs = [
            FontRun(font: menlo, location: 3, length: 100),
            FontRun(font: big, location: -5, length: 2),
            FontRun(font: big, location: 20, length: 2),
            FontRun(font: big, location: 1, length: 0),
        ]
        #expect(
            FontRun.normalized(runs, textLength: 5) == [
                FontRun(font: big, location: 0, length: 2),
                FontRun(font: menlo, location: 3, length: 2),
            ]
        )
    }
}
