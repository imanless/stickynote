import AppKit
import StickyNoteCore

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

    /// The font choices of the selected text, or, with nothing selected, of the text typed next.
    /// More than one when parts of the selection differ.
    var selectedFonts: Set<FontOverride> {
        let ranges = selectedTextRanges
        guard !ranges.isEmpty, let textStorage else {
            return [RichText.format(in: typingAttributes).font]
        }
        var fonts = Set<FontOverride>()
        for range in ranges {
            textStorage.enumerateAttributes(in: range) { attributes, _, _ in
                fonts.insert(RichText.format(in: attributes).font)
            }
        }
        return fonts
    }

    /// Turns `style` on for the selection, or off if all of it already has the style.
    /// With nothing selected, it applies to the text typed next. Can be undone.
    func toggle(_ style: TextStyle, using richText: RichText) {
        let isOn = !selectionHas(style)
        changeFormat(using: richText, actionName: style.displayName) { format in
            if isOn {
                format.styles.insert(style)
            } else {
                format.styles.remove(style)
            }
        }
    }

    /// Changes the font choices of the selection, or, with nothing selected, of the text typed
    /// next. Can be undone.
    func changeFont(using richText: RichText, actionName: String, _ change: (inout FontOverride) -> Void) {
        changeFormat(using: richText, actionName: actionName) { change(&$0.font) }
    }

    private func changeFormat(using richText: RichText, actionName: String, _ change: (inout RichText.Format) -> Void) {
        var typingFormat = RichText.format(in: typingAttributes)
        change(&typingFormat)
        typingAttributes = richText.attributes(for: typingFormat)

        let ranges = selectedTextRanges
        guard !ranges.isEmpty, let textStorage,
            shouldChangeText(inRanges: ranges.map { NSValue(range: $0) }, replacementStrings: nil)
        else { return }

        textStorage.beginEditing()
        for range in ranges {
            richText.update(textStorage, in: range, change)
        }
        textStorage.endEditing()
        didChangeText()
        undoManager?.setActionName(actionName)
    }

    /// Selected ranges that contain text, ignoring a plain insertion point.
    private var selectedTextRanges: [NSRange] {
        selectedRanges.map(\.rangeValue).filter { $0.length > 0 }
    }
}
