import AppKit
import StickyNoteCore
import Testing

@testable import StickyNote

@MainActor
struct RichTextTests {
    private let richText = RichText(font: FontSettings(family: nil, size: 14))

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

    @Test func stylesSurviveAFontWithoutBoldOrItalicFaces() {
        let papyrus = RichText(font: FontSettings(family: "Papyrus", size: 14))
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

    @Test func switchingFontsKeepsStyles() {
        let styles = [StyleRun(style: .italic, location: 0, length: 3)]
        let before = richText.attributedString(text: "abc def", styles: styles)

        let otherFont = RichText(font: FontSettings(family: "Helvetica", size: 20))
        let after = otherFont.attributedString(text: before.string, styles: RichText.styleRuns(of: before))

        #expect(RichText.styleRuns(of: after) == styles)
        #expect((after.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)?.pointSize == 20)
    }

    @Test func fontRunsSurviveARoundTrip() {
        let fontRuns = [
            FontRun(font: FontOverride(family: "Menlo"), location: 0, length: 5),
            FontRun(font: FontOverride(size: 24), location: 6, length: 3),
            FontRun(font: FontOverride(family: FontOverride.systemFamily, size: 10), location: 10, length: 4),
        ]
        let string = richText.attributedString(text: "Hello big wide world", styles: [], fontRuns: fontRuns)

        #expect(RichText.fontRuns(of: string) == fontRuns)
    }

    @Test func textWithOnlyItsOwnSizeKeepsTheNotesFont() throws {
        let menlo = RichText(font: FontSettings(family: "Menlo", size: 14))
        let string = menlo.attributedString(
            text: "big",
            styles: [],
            fontRuns: [FontRun(font: FontOverride(size: 24), location: 0, length: 3)]
        )
        let font = try #require(string.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)

        #expect(font.familyName == "Menlo")
        #expect(font.pointSize == 24)
    }

    @Test func boldTextKeepsItsOwnFont() throws {
        let string = richText.attributedString(
            text: "Title",
            styles: [StyleRun(style: .bold, location: 0, length: 5)],
            fontRuns: [FontRun(font: FontOverride(family: "Helvetica Neue", size: 20), location: 0, length: 5)]
        )
        let font = try #require(string.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)

        #expect(font.familyName == "Helvetica Neue")
        #expect(font.pointSize == 20)
        #expect(font.fontDescriptor.symbolicTraits.contains(.bold))
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
        #expect(font.familyName == NSFont.systemFont(ofSize: 14).familyName)
        #expect(RichText.styles(in: attributes) == [.bold, .underline])
        #expect(RichText.fontRuns(of: storage).isEmpty)
        #expect(attributes[.link] == nil)
        #expect(attributes[.foregroundColor] as? NSColor == NSColor.textColor)
    }
}

@MainActor
struct TextViewFormattingTests {
    private let richText = RichText(font: FontSettings(family: nil, size: 14))

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

    @Test func selectedTextGetsItsOwnFontUntilSetBackToTheNotes() {
        let textView = makeTextView("one two", selecting: NSRange(location: 4, length: 3))

        textView.changeFont(using: richText, actionName: "Font") { $0.family = "Menlo" }
        #expect(textView.selectedFonts == [FontOverride(family: "Menlo")])
        #expect(
            RichText.fontRuns(of: textView.attributedString()) == [
                FontRun(font: FontOverride(family: "Menlo"), location: 4, length: 3)
            ]
        )

        textView.changeFont(using: richText, actionName: "Font") { $0.family = nil }
        #expect(RichText.fontRuns(of: textView.attributedString()).isEmpty)
    }

    @Test func fontAndSizeAreChosenSeparately() {
        let textView = makeTextView("one two", selecting: NSRange(location: 0, length: 7))
        textView.changeFont(using: richText, actionName: "Font") { $0.family = "Menlo" }

        textView.setSelectedRange(NSRange(location: 0, length: 3))
        textView.changeFont(using: richText, actionName: "Text Size") { $0.size = 24 }

        #expect(
            RichText.fontRuns(of: textView.attributedString()) == [
                FontRun(font: FontOverride(family: "Menlo", size: 24), location: 0, length: 3),
                FontRun(font: FontOverride(family: "Menlo"), location: 3, length: 4),
            ]
        )
    }

    @Test func partlyChangedSelectionHasEveryFontInIt() {
        let textView = makeTextView("one two", selecting: NSRange(location: 0, length: 3))
        textView.changeFont(using: richText, actionName: "Text Size") { $0.size = 20 }

        textView.setSelectedRange(NSRange(location: 0, length: 7))

        #expect(textView.selectedFonts == [FontOverride(size: 20), FontOverride()])
    }

    @Test func togglingAStyleKeepsTheFont() {
        let textView = makeTextView("word", selecting: NSRange(location: 0, length: 4))
        textView.changeFont(using: richText, actionName: "Text Size") { $0.size = 20 }

        textView.toggle(.bold, using: richText)

        let string = textView.attributedString()
        #expect(RichText.fontRuns(of: string) == [FontRun(font: FontOverride(size: 20), location: 0, length: 4)])
        #expect(RichText.styleRuns(of: string) == [StyleRun(style: .bold, location: 0, length: 4)])
    }

    @Test func withNothingSelectedTheFontAppliesToTypedText() {
        let textView = makeTextView("one", selecting: NSRange(location: 3, length: 0))

        textView.changeFont(using: richText, actionName: "Text Size") { $0.size = 24 }
        textView.insertText(" two", replacementRange: textView.selectedRange())

        #expect(
            RichText.fontRuns(of: textView.attributedString()) == [
                FontRun(font: FontOverride(size: 24), location: 3, length: 4)
            ]
        )
    }

    @Test func withNothingSelectedTheStyleAppliesToTypedText() {
        let textView = makeTextView("one", selecting: NSRange(location: 3, length: 0))

        textView.toggle(.italic, using: richText)

        #expect(textView.selectionHas(.italic))
        #expect(RichText.styleRuns(of: textView.attributedString()).isEmpty)
    }
}

@MainActor
struct NoteTextViewTests {
    private func makeTextView(font: FontSettings) -> NoteTextView {
        let textView = NoteTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        textView.isRichText = true
        textView.formatting = RichText(font: font)
        return textView
    }

    @Test func copiedTextKeepsItsFormattingInAnotherNote() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("StickyNoteTests-\(UUID().uuidString)"))
        defer { pasteboard.releaseGlobally() }

        let source = makeTextView(font: FontSettings(family: "Menlo", size: 14))
        let styles = [StyleRun(style: .bold, location: 0, length: 3)]
        let fontRuns = [FontRun(font: FontOverride(size: 24), location: 0, length: 3)]
        source.textStorage?.setAttributedString(
            source.formatting.attributedString(text: "Big plain", styles: styles, fontRuns: fontRuns)
        )
        source.selectAll(nil)
        #expect(source.writeSelection(to: pasteboard, types: source.writablePasteboardTypes))
        #expect(pasteboard.types?.contains(.rtf) == true)  // Still pastes as rich text into other apps.

        let destination = makeTextView(font: FontSettings(family: "Helvetica", size: 14))
        #expect(destination.readSelection(from: pasteboard))

        let pasted = destination.attributedString()
        #expect(pasted.string == "Big plain")
        #expect(RichText.styleRuns(of: pasted) == styles)
        #expect(RichText.fontRuns(of: pasted) == fontRuns)
        // Text without a font of its own takes on the font of the note it's pasted into.
        let plainFont = try #require(pasted.attribute(.font, at: 4, effectiveRange: nil) as? NSFont)
        #expect(plainFont.familyName == "Helvetica")
    }
}
