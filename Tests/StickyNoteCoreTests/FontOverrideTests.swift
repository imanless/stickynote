import StickyNoteCore
import Testing

struct FontOverrideTests {
    private let defaults = FontSettings(family: "Helvetica Neue", size: 14)

    @Test func noOverrideUsesTheDefaults() {
        #expect(FontOverride().applied(to: defaults) == defaults)
    }

    @Test func ownSizeStillFollowsTheDefaultFont() {
        let font = FontOverride(size: 20).applied(to: defaults)
        #expect(font == FontSettings(family: "Helvetica Neue", size: 20))
    }

    @Test func ownFontStillFollowsTheDefaultSize() {
        let font = FontOverride(family: "Menlo").applied(to: defaults)
        #expect(font == FontSettings(family: "Menlo", size: 14))
    }

    @Test func systemFontCanBeChosenWhenTheDefaultIsAnotherFont() {
        let font = FontOverride(family: FontOverride.systemFamily).applied(to: defaults)
        #expect(font.family == nil)
    }

    @Test func ownSizeIsKeptInRange() {
        #expect(FontOverride(size: 500).applied(to: defaults).size == FontSettings.sizeRange.upperBound)
    }
}

struct StandardSizeTests {
    @Test(arguments: [(14.0, true, 16.0), (14.0, false, 13.0), (15.0, true, 16.0), (15.0, false, 14.0)])
    func stepsToTheNextStandardSize(from size: Double, larger: Bool, expected: Double) {
        #expect(FontSettings.nextStandardSize(from: size, larger: larger) == expected)
    }

    @Test func staysPutAtEitherEnd() {
        #expect(FontSettings.nextStandardSize(from: 48, larger: true) == 48)
        #expect(FontSettings.nextStandardSize(from: 10, larger: false) == 10)
    }

    @Test func choicesIncludeAnUnusualCurrentSize() {
        #expect(FontSettings.sizeChoices(including: 15).contains(15))
        #expect(FontSettings.sizeChoices(including: nil) == FontSettings.standardSizes)
    }
}
