import AppKit
import StickyNoteCore
import Testing

@testable import StickyNote

@MainActor
struct NoteWindowControllerTests {
    private let model = NoteModel(note: Note(text: "Title body", frame: NoteFrame(x: 0, y: 0, width: 260, height: 240)))
    private let controller: NoteWindowController
    private let textView: NoteTextView

    init() throws {
        // Only read from, so nothing is saved.
        let settings = AppSettings(defaults: try #require(UserDefaults(suiteName: "StickyNoteTests-\(UUID())")))
        controller = NoteWindowController(model: model, settings: settings)
        textView = try #require(controller.window?.firstResponder as? NoteTextView)
    }

    @Test func rightClickMenuOffersFontsAndSizesForTheText() throws {
        let event = try #require(
            NSEvent.mouseEvent(
                with: .rightMouseDown,
                location: .zero,
                modifierFlags: [],
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                eventNumber: 0,
                clickCount: 1,
                pressure: 1
            )
        )
        let menu = try #require(controller.textView(textView, menu: NSMenu(), for: event, at: 0))

        let fonts = try #require(menu.item(withTitle: "Font")?.submenu)
        #expect(fonts.item(withTitle: "Menlo") != nil)
        #expect(menu.item(withTitle: "Size")?.submenu?.item(withTitle: "24 pt") != nil)
    }

    @Test func sizeChosenForSelectedTextIsSavedAndChecked() throws {
        textView.setSelectedRange(NSRange(location: 0, length: 5))
        let sizes = try #require(FontMenus.sizeItem(target: controller).submenu)
        let big = try #require(sizes.item(withTitle: "24 pt"))
        let sameAsNote = try #require(sizes.item(withTitle: "Same as Note"))

        controller.changeTextSize(big)

        #expect(model.note.fontRuns == [FontRun(font: FontOverride(size: 24), location: 0, length: 5)])
        #expect(controller.validateMenuItem(big))
        #expect(big.state == .on)
        _ = controller.validateMenuItem(sameAsNote)
        #expect(sameAsNote.state == .off)

        controller.changeTextSize(sameAsNote)
        #expect(model.note.fontRuns.isEmpty)
    }

    @Test func addToNotesNeedsText() throws {
        let item = NSMenuItem(
            title: "Add to Notes…", action: #selector(NoteWindowController.addToNotes(_:)), keyEquivalent: "")
        #expect(controller.validateMenuItem(item) == (AppleNotes.icon != nil))

        textView.selectAll(nil)
        textView.insertText("  \n", replacementRange: textView.selectedRange())
        #expect(!controller.validateMenuItem(item))
    }
}
