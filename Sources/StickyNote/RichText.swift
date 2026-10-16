import AppKit
import StickyNoteCore

/// Draws a note's text in the user's chosen font, and converts between the text system's
/// attributed strings and a note's text plus `StyleRun`s.
///
/// Notes keep only the styles in `TextStyle`. Anything else, such as the fonts, sizes and colors
/// of pasted text, is replaced by the note's standard look, so a note looks the same after
/// relaunching as it did while editing.
///
/// `@unchecked Sendable` because its only state is an `NSFont`, which is immutable and safe to
/// share between threads, but isn't marked `Sendable` by AppKit.
struct RichText: @unchecked Sendable {
    /// Bold and italic are recorded with these markers rather than read back from the font,
    /// because not every font has a bold or italic face to show them with.
    static let boldKey = NSAttributedString.Key("io.github.imanless.StickyNote.bold")
    static let italicKey = NSAttributedString.Key("io.github.imanless.StickyNote.italic")

    /// How far synthesized italics lean, for fonts without an italic face.
    private static let syntheticObliqueness = 0.2
    /// How thick synthesized bold strokes are (as a percentage of font size), for fonts without a bold face.
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

extension NSTextView {
    /// Whether all of the selected text has `style`, or, with nothing selected, whether the
    /// text typed next will.
    func selectionHas(_ style: TextStyle) -> Bool {
        let ranges = selectedTextRanges
        guard !ranges.isEmpty, let textStorage else {
            return RichText.styles(in: typingAttributes).contains(style)
        }
        return ranges.allSatisfy { range in
            var hasStyle = true
            textStorage.enumerateAttributes(in: range) { attributes, _, stop in
                if !RichText.styles(in: attributes).contains(style) {
                    hasStyle = false
                    stop.pointee = true
                }
            }
            return hasStyle
        }
    }

    /// Turns `style` on for the selection, or off if all of it already has the style.
    /// With nothing selected, it applies to the text typed next. Can be undone.
    func toggle(_ style: TextStyle, using richText: RichText) {
        let isOn = !selectionHas(style)
        func updating(_ attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
            var styles = RichText.styles(in: attributes)
            if isOn {
                styles.insert(style)
            } else {
                styles.remove(style)
            }
            return richText.attributes(for: styles)
        }

        typingAttributes = updating(typingAttributes)

        let ranges = selectedTextRanges
        guard !ranges.isEmpty, let textStorage,
            shouldChangeText(inRanges: ranges.map { NSValue(range: $0) }, replacementStrings: nil)
        else { return }

        textStorage.beginEditing()
        for range in ranges {
            textStorage.enumerateAttributes(in: range) { attributes, subrange, _ in
                textStorage.setAttributes(updating(attributes), range: subrange)
            }
        }
        textStorage.endEditing()
        didChangeText()
        undoManager?.setActionName(style.displayName)
    }

    /// The selected ranges that contain text, ignoring a plain insertion point.
    private var selectedTextRanges: [NSRange] {
        selectedRanges.map(\.rangeValue).filter { $0.length > 0 }
    }
}

extension TextStyle {
    var displayName: String {
        switch self {
        case .bold: "Bold"
        case .italic: "Italic"
        case .underline: "Underline"
        case .strikethrough: "Strikethrough"
        }
    }

    /// The standard macOS shortcuts (⌘B, ⌘I, ⌘U). Strikethrough has no standard one.
    private var keyEquivalent: String {
        switch self {
        case .bold: "b"
        case .italic: "i"
        case .underline: "u"
        case .strikethrough: ""
        }
    }

    /// A menu item that toggles this style. With no `target`, it acts on the frontmost note.
    @MainActor
    func menuItem(target: AnyObject? = nil) -> NSMenuItem {
        let item = NSMenuItem(
            title: displayName,
            action: #selector(NoteWindowController.toggleTextStyle(_:)),
            keyEquivalent: keyEquivalent
        )
        item.representedObject = self
        item.target = target
        return item
    }
}
