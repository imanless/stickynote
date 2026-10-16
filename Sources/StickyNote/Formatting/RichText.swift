import AppKit
import StickyNoteCore

/// Draws a note's text in the user's chosen font, and converts between attributed strings
/// and a note's text plus `StyleRun`s.
///
/// Only the styles in `TextStyle` are kept. Other formatting, such as the fonts and colors of
/// pasted text, is replaced by the note's own look, so a note looks the same after relaunching.
///
/// `@unchecked Sendable` because its only state is an `NSFont`, which is immutable and safe to
/// share between threads but isn't marked `Sendable` by AppKit.
struct RichText: @unchecked Sendable {
    /// Bold and italic are recorded with these markers rather than read back from the font,
    /// because not every font has a bold or italic face to show them with.
    static let boldKey = NSAttributedString.Key("io.github.imanless.StickyNote.bold")
    static let italicKey = NSAttributedString.Key("io.github.imanless.StickyNote.italic")

    /// Lean of synthesized italics, for fonts without an italic face.
    private static let syntheticObliqueness = 0.2
    /// Stroke width of synthesized bold (percent of the font size), for fonts without a bold face.
    private static let syntheticBoldStrokeWidth = -3.0

    /// The regular face of the user's chosen font.
    let font: NSFont

    var baseAttributes: [NSAttributedString.Key: Any] {
        attributes(for: [])
    }

    func attributes(for styles: Set<TextStyle>) -> [NSAttributedString.Key: Any] {
        let isBold = styles.contains(.bold)
        let isItalic = styles.contains(.italic)

        var traits = font.fontDescriptor.symbolicTraits
        if isBold { traits.insert(.bold) }
        if isItalic { traits.insert(.italic) }
        let styledFont =
            NSFont(descriptor: font.fontDescriptor.withSymbolicTraits(traits), size: font.pointSize) ?? font

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
        if styles.contains(.underline) {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if styles.contains(.strikethrough) {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        return attributes
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

    func attributedString(text: String, styles: [StyleRun]) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: baseAttributes)
        for run in StyleRun.normalized(styles, textLength: result.length) {
            let range = NSRange(location: run.location, length: run.length)
            result.enumerateAttributes(in: range) { attributes, subrange, _ in
                let styles = Self.styles(in: attributes).union([run.style])
                result.setAttributes(self.attributes(for: styles), range: subrange)
            }
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

    /// Redraws `range` in the note's look, keeping only the supported styles.
    func normalize(_ string: NSMutableAttributedString, in range: NSRange) {
        string.enumerateAttributes(in: range) { attributes, subrange, _ in
            string.setAttributes(self.attributes(for: Self.styles(in: attributes)), range: subrange)
        }
    }
}
