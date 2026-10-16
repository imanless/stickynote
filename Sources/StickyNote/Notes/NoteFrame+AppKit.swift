import AppKit
import StickyNoteCore

extension NoteFrame {
    init(_ rect: NSRect) {
        self.init(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.size.width,
            height: rect.size.height
        )
    }

    var rect: NSRect {
        NSRect(x: x, y: y, width: width, height: height)
    }
}
