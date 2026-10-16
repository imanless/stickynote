import AppKit
import StickyNoteCore

/// A note's text view. Text copied from a note is also put on the pasteboard in the note's own
/// format, so pasting it into a note keeps its chosen fonts and synthesized bold and italics,
/// which the rich text formats other apps read can't carry.
final class NoteTextView: NSTextView {
    static let noteTextType = NSPasteboard.PasteboardType("io.github.imanless.StickyNote.text")

    private struct Clipping: Codable {
        var text: String
        var styles: [StyleRun]
        var fontRuns: [FontRun]
    }

    /// Draws the note's text, including pasted text.
    var formatting = RichText(font: .standard)

    override var writablePasteboardTypes: [NSPasteboard.PasteboardType] {
        [Self.noteTextType] + super.writablePasteboardTypes
    }

    override var readablePasteboardTypes: [NSPasteboard.PasteboardType] {
        [Self.noteTextType] + super.readablePasteboardTypes
    }

    override func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
        guard super.writeSelection(to: pboard, types: types.filter { $0 != Self.noteTextType }) else { return false }
        // Only a single selected range; a pasteboard without this type falls back to rich text.
        if types.contains(Self.noteTextType), let textStorage, selectedRanges.count == 1 {
            let selection = textStorage.attributedSubstring(from: selectedRange())
            let clipping = Clipping(
                text: selection.string,
                styles: RichText.styleRuns(of: selection),
                fontRuns: RichText.fontRuns(of: selection)
            )
            if let data = try? JSONEncoder().encode(clipping) {
                pboard.addTypes([Self.noteTextType], owner: nil)
                pboard.setData(data, forType: Self.noteTextType)
            }
        }
        return true
    }

    override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        guard type == Self.noteTextType else { return super.readSelection(from: pboard, type: type) }
        guard let data = pboard.data(forType: type),
            let clipping = try? JSONDecoder().decode(Clipping.self, from: data)
        else {
            return pboard.availableType(from: super.readablePasteboardTypes).map {
                super.readSelection(from: pboard, type: $0)
            } ?? false
        }

        let range = rangeForUserTextChange
        guard range.location != NSNotFound, let textStorage,
            shouldChangeText(in: range, replacementString: clipping.text)
        else { return false }
        let string = formatting.attributedString(
            text: clipping.text,
            styles: clipping.styles,
            fontRuns: clipping.fontRuns
        )
        textStorage.replaceCharacters(in: range, with: string)
        didChangeText()
        setSelectedRange(NSRange(location: range.location + string.length, length: 0))
        return true
    }
}
