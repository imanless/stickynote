import AppKit
import StickyNoteCore

/// The Font and Size submenus, which change the selected text. "Same as Note" removes the text's
/// own choice, so it follows the note's font again.
///
/// With no `target`, they act on the frontmost note.
@MainActor
enum FontMenus {
    static func fontItem(target: AnyObject? = nil) -> NSMenuItem {
        let choices = [("System Font", FontOverride.systemFamily)] + FontSettings.installedFamilies.map { ($0, $0) }
        return submenuItem(
            "Font",
            choices: choices,
            action: #selector(NoteWindowController.changeTextFont(_:)),
            target: target
        )
    }

    static func sizeItem(target: AnyObject? = nil) -> NSMenuItem {
        submenuItem(
            "Size",
            choices: FontSettings.standardSizes.map { ("\($0.formatted()) pt", $0) },
            action: #selector(NoteWindowController.changeTextSize(_:)),
            target: target
        )
    }

    /// "Same as Note", then an item for each choice, which sends `action` with the choice's value.
    private static func submenuItem(
        _ title: String,
        choices: [(title: String, value: Any)],
        action: Selector,
        target: AnyObject?
    ) -> NSMenuItem {
        let menu = NSMenu(title: title)
        menu.addItem(withTitle: "Same as Note", action: action, keyEquivalent: "").target = target
        menu.addItem(.separator())
        for choice in choices {
            let item = menu.addItem(withTitle: choice.title, action: action, keyEquivalent: "")
            item.representedObject = choice.value
            item.target = target
        }

        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }
}
