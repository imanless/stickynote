import AppKit
import StickyNoteCore

extension NoteColor {
    var displayName: String {
        switch self {
        case .yellow: "Yellow"
        case .pink: "Pink"
        case .blue: "Blue"
        case .green: "Green"
        case .purple: "Purple"
        case .gray: "Gray"
        }
    }

    /// Light "paper" tones. Notes always use the light appearance, so text on them stays dark.
    var nsColor: NSColor {
        switch self {
        case .yellow: NSColor(srgbRed: 1.00, green: 0.96, blue: 0.62, alpha: 1)
        case .pink: NSColor(srgbRed: 0.98, green: 0.80, blue: 0.87, alpha: 1)
        case .blue: NSColor(srgbRed: 0.76, green: 0.89, blue: 0.98, alpha: 1)
        case .green: NSColor(srgbRed: 0.80, green: 0.95, blue: 0.78, alpha: 1)
        case .purple: NSColor(srgbRed: 0.87, green: 0.81, blue: 0.97, alpha: 1)
        case .gray: NSColor(srgbRed: 0.91, green: 0.91, blue: 0.91, alpha: 1)
        }
    }
}

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
