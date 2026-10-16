import AppKit
import StickyNoteCore
import Testing

@testable import StickyNote

@MainActor
struct RichTextTests {
    private let richText = RichText(font: .systemFont(ofSize: 14))

    @Test func stylesSurviveARoundTrip() {
        let styles = [
            StyleRun(style: .bold, location: 0, length: 5),
            StyleRun(style: .italic, location: 3, length: 6),
            StyleRun(style: .underline, location: 6, length: 3),
            StyleRun(style: .strikethrough, location: 10, length: 4),
        ]
        let string = richText.attributedString(text: "Hello big wide world", styles: styles)

        #expect(RichText.styleRuns(of: string) == styles)
    }

    @Test func overlappingBoldAndItalicMakeBoldItalicText() throws {
        let string = richText.attributedString(
            text: "both",
            styles: [
                StyleRun(style: .bold, location: 0, length: 4),
                StyleRun(style: .italic, location: 0, length: 4),
            ]
        )
        let font = try #require(string.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)

        #expect(font.fontDescriptor.symbolicTraits.isSuperset(of: [.bold, .italic]))
        #expect(font.pointSize == 14)
    }

    @Test func stylesSurviveAFontWithoutBoldOrItalicFaces() throws {
        let papyrus = RichText(font: try #require(NSFont(name: "Papyrus", size: 14)))
        let styles = [
            StyleRun(style: .bold, location: 0, length: 4),
            StyleRun(style: .italic, location: 5, length: 6),
        ]
        let string = papyrus.attributedString(text: "Bold italic", styles: styles)

        #expect(RichText.styleRuns(of: string) == styles)
        // Shown with synthesized bold and italics instead.
        #expect(string.attribute(.strokeWidth, at: 0, effectiveRange: nil) != nil)
        #expect(string.attribute(.obliqueness, at: 5, effectiveRange: nil) != nil)
    }

    @Test func switchingFontsKeepsStyles() throws {
        let styles = [StyleRun(style: .italic, location: 0, length: 3)]
        let before = richText.attributedString(text: "abc def", styles: styles)

        let otherFont = RichText(font: try #require(NSFont(name: "Helvetica", size: 20)))
        let after = otherFont.attributedString(text: before.string, styles: RichText.styleRuns(of: before))

        #expect(RichText.styleRuns(of: after) == styles)
        #expect((after.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)?.pointSize == 20)
    }

    @Test func rangesCountEmojiTheWayTheTextSystemDoes() {
        // "👋" is one character but two UTF-16 code units, so "hi" starts at 3.
        let string = richText.attributedString(
            text: "👋 hi",
            styles: [StyleRun(style: .bold, location: 3, length: 2)]
        )
        var range = NSRange()
        _ = string.attribute(RichText.boldKey, at: 3, effectiveRange: &range)

        #expect((string.string as NSString).substring(with: range) == "hi")
        #expect(RichText.styles(in: string.attributes(at: 3, effectiveRange: nil)) == [.bold])
        #expect(RichText.styles(in: string.attributes(at: 0, effectiveRange: nil)).isEmpty)
    }

    @Test func stylesBeyondTheEndOfTheTextAreIgnoredSafely() {
        let string = richText.attributedString(
            text: "hi",
            styles: [StyleRun(style: .bold, location: 1, length: 50)]
        )
        #expect(RichText.styleRuns(of: string) == [StyleRun(style: .bold, location: 1, length: 1)])
    }

    @Test func pastedTextKeepsStylesButLosesOtherFormatting() throws {
        let pasted = NSAttributedString(
            string: "Big red link",
            attributes: [
                .font: try #require(NSFont(name: "Helvetica-Bold", size: 30)),
                .foregroundColor: NSColor.red,
                .link: try #require(URL(string: "https://example.com")),
                .underlineStyle: NSUnderlineStyle.double.rawValue,
            ]
        )
        let storage = NSMutableAttributedString(string: "Note: ", attributes: richText.baseAttributes)
        storage.append(pasted)

        richText.normalize(storage, in: NSRange(location: 6, length: pasted.length))

        let attributes = storage.attributes(at: 6, effectiveRange: nil)
        let font = try #require(attributes[.font] as? NSFont)
        #expect(font.pointSize == 14)
        #expect(font.familyName == richText.font.familyName)
        #expect(RichText.styles(in: attributes) == [.bold, .underline])
        #expect(attributes[.link] == nil)
        #expect(attributes[.foregroundColor] as? NSColor == NSColor.textColor)
    }
}

@MainActor
struct TextViewFormattingTests {
    private let richText = RichText(font: .systemFont(ofSize: 14))

    private func makeTextView(_ text: String, selecting range: NSRange) -> NSTextView {
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        textView.isRichText = true
        textView.textStorage?.setAttributedString(richText.attributedString(text: text, styles: []))
        textView.setSelectedRange(range)
        return textView
    }

    @Test func togglingBoldTwiceTurnsItOnThenOff() {
        let textView = makeTextView("one two", selecting: NSRange(location: 0, length: 3))

        textView.toggle(.bold, using: richText)
        #expect(textView.selectionHas(.bold))
        #expect(RichText.styleRuns(of: textView.attributedString()) == [StyleRun(style: .bold, location: 0, length: 3)])

        textView.toggle(.bold, using: richText)
        #expect(!textView.selectionHas(.bold))
        #expect(RichText.styleRuns(of: textView.attributedString()).isEmpty)
    }

    @Test func partlyStyledSelectionBecomesFullyStyled() {
        let textView = makeTextView("one two", selecting: NSRange(location: 0, length: 3))
        textView.toggle(.underline, using: richText)

        textView.setSelectedRange(NSRange(location: 0, length: 7))
        #expect(!textView.selectionHas(.underline))
        textView.toggle(.underline, using: richText)

        #expect(
            RichText.styleRuns(of: textView.attributedString()) == [
                StyleRun(style: .underline, location: 0, length: 7)
            ]
        )
    }

    @Test func togglingOneStyleKeepsTheOthers() {
        let textView = makeTextView("word", selecting: NSRange(location: 0, length: 4))

        textView.toggle(.bold, using: richText)
        textView.toggle(.italic, using: richText)
        textView.toggle(.bold, using: richText)

        #expect(
            RichText.styleRuns(of: textView.attributedString()) == [StyleRun(style: .italic, location: 0, length: 4)])
    }

    @Test func withNothingSelectedTheStyleAppliesToTypedText() {
        let textView = makeTextView("one", selecting: NSRange(location: 3, length: 0))

        textView.toggle(.italic, using: richText)

        #expect(textView.selectionHas(.italic))
        #expect(RichText.styleRuns(of: textView.attributedString()).isEmpty)
    }
}
