import AppKit
import StickyNoteCore

extension TextStyle {
    var displayName: String {
        switch self {
        case .bold: "Bold"
        case .italic: "Italic"
        case .underline: "Underline"
        case .strikethrough: "Strikethrough"
        }
    }

    /// The standard macOS shortcuts. Strikethrough has no standard one.
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
