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

    /// Selected ranges that contain text, ignoring a plain insertion point.
    private var selectedTextRanges: [NSRange] {
        selectedRanges.map(\.rangeValue).filter { $0.length > 0 }
    }
}
