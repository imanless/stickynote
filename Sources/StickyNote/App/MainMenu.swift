import AppKit
import StickyNoteCore

/// Builds the menu bar in code, since the app has no storyboard or XIB.
///
/// Items with a `nil` target are sent along the responder chain, so note-specific actions
/// reach the `NoteWindowController` of the frontmost note.
@MainActor
enum MainMenu {
    static func make(appName: String, updater: AppUpdater) -> NSMenu {
        let windowMenu = windowMenu()
        NSApp.windowsMenu = windowMenu  // AppKit lists every open note here.

        let mainMenu = NSMenu()
        let submenus = [
            appMenu(appName: appName, updater: updater), fileMenu(), editMenu(), formatMenu(), noteMenu(), windowMenu,
        ]
        for submenu in submenus {
            let item = NSMenuItem(title: submenu.title, action: nil, keyEquivalent: "")
            item.submenu = submenu
            mainMenu.addItem(item)
        }
        return mainMenu
    }

    private static func appMenu(appName: String, updater: AppUpdater) -> NSMenu {
        let menu = NSMenu(title: appName)
        menu.addItem(
            withTitle: "About \(appName)",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        menu.addItem(updater.makeMenuItem())
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(AppDelegate.showSettings(_:)), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        menu.addItem(
            withTitle: "Hide Others",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        ).keyEquivalentModifierMask = [.command, .option]
        menu.addItem(
            withTitle: "Show All",
            action: #selector(NSApplication.unhideAllApplications(_:)),
            keyEquivalent: ""
        )
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    private static func fileMenu() -> NSMenu {
        let menu = NSMenu(title: "File")
        menu.addItem(withTitle: "New Note", action: #selector(AppDelegate.newNote(_:)), keyEquivalent: "n")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Delete Note", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        return menu
    }

    private static func editMenu() -> NSMenu {
        // Without these items, standard shortcuts such as ⌘C and ⌘V don't work in text fields.
        let menu = NSMenu(title: "Edit")
        menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        menu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
            .keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(.separator())
        menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(
            withTitle: "Paste and Match Style",
            action: #selector(NSTextView.pasteAsPlainText(_:)),
            keyEquivalent: "v"
        ).keyEquivalentModifierMask = [.command, .option, .shift]
        menu.addItem(withTitle: "Delete", action: #selector(NSText.delete(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        return menu
    }

    private static func formatMenu() -> NSMenu {
        let menu = NSMenu(title: "Format")
        for style in TextStyle.allCases {
            menu.addItem(style.menuItem())
        }
        menu.addItem(.separator())
        menu.addItem(FontMenus.fontItem())
        menu.addItem(FontMenus.sizeItem())
        return menu
    }

    private static func noteMenu() -> NSMenu {
        let menu = NSMenu(title: "Note")
        menu.addItem(
            withTitle: "Keep on Top",
            action: #selector(NoteWindowController.toggleKeepOnTop(_:)),
            keyEquivalent: "p"
        ).keyEquivalentModifierMask = [.command, .shift]

        menu.addItem(.separator())
        menu.addItem(.sectionHeader(title: "Text Size"))
        menu.addItem(
            withTitle: "Bigger",
            action: #selector(NoteWindowController.makeTextBigger(_:)),
            keyEquivalent: "+"
        )
        menu.addItem(
            withTitle: "Smaller",
            action: #selector(NoteWindowController.makeTextSmaller(_:)),
            keyEquivalent: "-"
        )

        menu.addItem(.separator())
        menu.addItem(.sectionHeader(title: "Color"))
        for (index, color) in NoteColor.allCases.enumerated() {
            let item = menu.addItem(
                withTitle: color.displayName,
                action: #selector(NoteWindowController.changeNoteColor(_:)),
                keyEquivalent: "\(index + 1)"
            )
            item.representedObject = color
        }
        return menu
    }

    private static func windowMenu() -> NSMenu {
        let menu = NSMenu(title: "Window")
        menu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        menu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Bring All to Front",
            action: #selector(NSApplication.arrangeInFront(_:)),
            keyEquivalent: ""
        )
        return menu
    }
}
