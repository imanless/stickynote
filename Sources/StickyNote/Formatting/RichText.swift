import AppKit
import StickyNoteCore

/// Draws a note's text in the note's font, and converts between attributed strings and a
/// note's text plus `StyleRun`s and `FontRun`s.
///
/// Only the styles in `TextStyle` and fonts chosen in the app are kept. Other formatting, such as
/// the fonts and colors of text pasted from other apps, is replaced by the note's own look, so a
/// note looks the same after relaunching.
struct RichText: Sendable {
    /// Bold and italic are recorded with these markers rather than read back from the font,
    /// because not every font has a bold or italic face to show them with.
    static let boldKey = NSAttributedString.Key("io.github.imanless.StickyNote.bold")
    static let italicKey = NSAttributedString.Key("io.github.imanless.StickyNote.italic")
    /// A font or size chosen for part of the text is recorded with these markers, so it can be
    /// told apart from the note's font, which the text keeps following for anything not chosen.
    static let fontFamilyKey = NSAttributedString.Key("io.github.imanless.StickyNote.fontFamily")
    static let fontSizeKey = NSAttributedString.Key("io.github.imanless.StickyNote.fontSize")

    /// Lean of synthesized italics, for fonts without an italic face.
    private static let syntheticObliqueness = 0.2
    /// Stroke width of synthesized bold (percent of the font size), for fonts without a bold face.
    private static let syntheticBoldStrokeWidth = -3.0

    /// The formatting of one stretch of text.
    struct Format: Equatable {
        var styles: Set<TextStyle> = []
        var font = FontOverride()
    }

    /// The note's font, for text without a font of its own.
    let font: FontSettings

    var baseAttributes: [NSAttributedString.Key: Any] {
        attributes(for: Format())
    }

    func attributes(for format: Format) -> [NSAttributedString.Key: Any] {
        let isBold = format.styles.contains(.bold)
        let isItalic = format.styles.contains(.italic)

        let regularFont = format.font.applied(to: font).nsFont
        var traits = regularFont.fontDescriptor.symbolicTraits
        if isBold { traits.insert(.bold) }
        if isItalic { traits.insert(.italic) }
        let styledFont =
            NSFont(descriptor: regularFont.fontDescriptor.withSymbolicTraits(traits), size: regularFont.pointSize)
            ?? regularFont

        var attributes: [NSAttributedString.Key: Any] = [
            .font: styledFont,
            .foregroundColor: NSColor.textColor,
            Self.boldKey: isBold,
            Self.italicKey: isItalic,
        ]
        let actualTraits = styledFont.fontDescriptor.symbolicTraits
        if isBold && !actualTraits.contains(.bold) {
            attributes[.strokeWidth] = Self.syntheticBoldStrokeWidth
        }
        if isItalic && !actualTraits.contains(.italic) {
            attributes[.obliqueness] = Self.syntheticObliqueness
        }
        if format.styles.contains(.underline) {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if format.styles.contains(.strikethrough) {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        attributes[Self.fontFamilyKey] = format.font.family
        attributes[Self.fontSizeKey] = format.font.size
        return attributes
    }

    static func format(in attributes: [NSAttributedString.Key: Any]) -> Format {
        Format(
            styles: styles(in: attributes),
            font: FontOverride(family: attributes[fontFamilyKey] as? String, size: attributes[fontSizeKey] as? Double)
        )
    }

    static func styles(in attributes: [NSAttributedString.Key: Any]) -> Set<TextStyle> {
        // Text pasted from other apps has no markers, so fall back to its font's traits.
        let fontTraits = (attributes[.font] as? NSFont)?.fontDescriptor.symbolicTraits ?? []
        var styles = Set<TextStyle>()
        if attributes[boldKey] as? Bool ?? fontTraits.contains(.bold) {
            styles.insert(.bold)
        }
        if attributes[italicKey] as? Bool ?? fontTraits.contains(.italic) {
            styles.insert(.italic)
        }
        if (attributes[.underlineStyle] as? Int ?? 0) != 0 {
            styles.insert(.underline)
        }
        if (attributes[.strikethroughStyle] as? Int ?? 0) != 0 {
            styles.insert(.strikethrough)
        }
        return styles
    }

    func attributedString(text: String, styles: [StyleRun], fontRuns: [FontRun] = []) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: baseAttributes)
        for run in FontRun.normalized(fontRuns, textLength: result.length) {
            update(result, in: NSRange(location: run.location, length: run.length)) { $0.font = run.font }
        }
        for run in StyleRun.normalized(styles, textLength: result.length) {
            update(result, in: NSRange(location: run.location, length: run.length)) { $0.styles.insert(run.style) }
        }
        return result
    }

    static func styleRuns(of string: NSAttributedString) -> [StyleRun] {
        var runs: [StyleRun] = []
        string.enumerateAttributes(in: NSRange(location: 0, length: string.length)) { attributes, range, _ in
            for style in styles(in: attributes) {
                runs.append(StyleRun(style: style, location: range.location, length: range.length))
            }
        }
        return StyleRun.normalized(runs, textLength: string.length)
    }

    static func fontRuns(of string: NSAttributedString) -> [FontRun] {
        var runs: [FontRun] = []
        string.enumerateAttributes(in: NSRange(location: 0, length: string.length)) { attributes, range, _ in
            runs.append(FontRun(font: format(in: attributes).font, location: range.location, length: range.length))
        }
        return FontRun.normalized(runs, textLength: string.length)
    }

    /// Redraws `range` in the note's look, keeping only the supported styles and chosen fonts.
    func normalize(_ string: NSMutableAttributedString, in range: NSRange) {
        update(string, in: range) { _ in }
    }

    /// Redraws each differently formatted part of `range` with its format changed by `change`.
    func update(_ string: NSMutableAttributedString, in range: NSRange, _ change: (inout Format) -> Void) {
        string.enumerateAttributes(in: range) { attributes, subrange, _ in
            var format = Self.format(in: attributes)
            change(&format)
            string.setAttributes(self.attributes(for: format), range: subrange)
        }
    }
}
