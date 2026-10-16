import AppKit
import StickyNoteCore
import SwiftUI

@MainActor
protocol NoteWindowControllerDelegate: AnyObject {
    func noteWindowControllerDidChangeNote(_ controller: NoteWindowController)
    func noteWindowControllerDidDeleteNote(_ controller: NoteWindowController)
}

/// Owns the window for one note: its text, color, "keep on top" level, and deletion.
/// As in Apple's Stickies, closing a note's window deletes the note.
final class NoteWindowController: NSWindowController, NSWindowDelegate, NSMenuItemValidation,
    NSTextViewDelegate, NSTextStorageDelegate
{
    private static let minimumSize = NSSize(width: 160, height: 120)

    let model: NoteModel
    weak var delegate: (any NoteWindowControllerDelegate)?

    /// Provides the app-wide default font that the note's own font choices are applied to.
    private let settings: AppSettings
    /// The font the text is drawn in: the default, with the note's own choices applied.
    private var font: FontSettings

    private let textView = NoteWindowController.makeTextView()
    /// Distinguishes the user deleting the note from the window closing for any other reason.
    private var isDeleting = false

    init(model: NoteModel, settings: AppSettings) {
        self.model = model
        self.settings = settings
        font = model.font.applied(to: settings.font)
        textView.formatting = RichText(font: font)
        let window = NSWindow(
            contentRect: model.frame.rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        configure(window)
        applyNoteState()
        model.onChange = { [weak self] in self?.noteDidChange() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Setup

    private func configure(_ window: NSWindow) {
        window.isReleasedWhenClosed = false  // This controller owns the window.
        window.isRestorable = false  // Notes are restored from the notes file instead.
        window.tabbingMode = .disallowed
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.appearance = NSAppearance(named: .aqua)  // Dark text on light paper, even in Dark Mode.
        window.minSize = Self.minimumSize

        installTextView(in: window)
        installTitlebarControls(in: window)

        window.setFrame(Self.reachableFrame(for: model.frame.rect), display: false)
        // Assigned last so the setup above isn't reported as the user moving the window.
        window.delegate = self
    }

    private static func makeTextView() -> NoteTextView {
        let textView = NoteTextView(frame: .zero)
        textView.isRichText = true
        textView.allowsUndo = true
        textView.importsGraphics = false
        textView.usesFontPanel = false  // Notes keep only the fonts chosen from their own Font menus.
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 8, height: 4)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        return textView
    }

    private func installTextView(in window: NSWindow) {
        redrawText()
        textView.delegate = self
        textView.textStorage?.delegate = self

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.documentView = textView

        let contentView = NSView()
        contentView.addSubview(scrollView)
        window.contentView = contentView

        // Start the text below the title bar, which is transparent and shows the note's color.
        let contentTop = (window.contentLayoutGuide as? NSLayoutGuide)?.topAnchor ?? contentView.topAnchor
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentTop),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        window.makeFirstResponder(textView)
    }

    /// Fills the text view from the note, drawn in the current `font`.
    private func redrawText() {
        guard let textStorage = textView.textStorage else { return }
        let formatting = textView.formatting
        let selection = textView.selectedRanges
        textStorage.setAttributedString(
            formatting.attributedString(text: model.text, styles: model.styles, fontRuns: model.fontRuns)
        )
        textView.selectedRanges = selection  // Same text, so the old selection still fits.
        if textStorage.length == 0 {
            textView.typingAttributes = formatting.baseAttributes
        }
        // Undo steps recorded before the redraw would bring back the old font.
        textView.undoManager?.removeAllActions()
    }

    private func installTitlebarControls(in window: NSWindow) {
        let controls = NSHostingView(rootView: NoteTitlebarControls(model: model, settings: settings))
        controls.frame.size = controls.fittingSize
        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = controls
        accessory.layoutAttribute = .trailing
        window.addTitlebarAccessoryViewController(accessory)
    }

    /// Moves a note saved on a display that is no longer connected back onto the main screen.
    private static func reachableFrame(for frame: NSRect) -> NSRect {
        let screens = NSScreen.screens.map { NoteFrame($0.visibleFrame) }
        guard !NoteFrame(frame).isReachable(on: screens),
            let visibleFrame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame
        else {
            return frame
        }
        var centered = frame
        centered.origin = NSPoint(
            x: visibleFrame.midX - frame.width / 2,
            y: visibleFrame.midY - frame.height / 2
        )
        return centered
    }

    // MARK: - Reacting to note changes

    private func noteDidChange() {
        applyNoteState()
        updateFont()
        delegate?.noteWindowControllerDidChangeNote(self)
    }

    /// Redraws the text if the note's own font or the app-wide default now gives another font.
    func updateFont() {
        let newFont = model.font.applied(to: settings.font)
        guard newFont != font else { return }
        font = newFont
        textView.formatting = RichText(font: newFont)
        redrawText()
    }

    private func applyNoteState() {
        guard let window else { return }
        window.backgroundColor = model.color.nsColor
        let title = model.note.title
        window.title = title.isEmpty ? "New Note" : title

        if model.isPinned {
            // Float above the normal windows of every app, follow the user to every Space,
            // and stay visible on top of apps running in full screen.
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            window.level = .normal
            window.collectionBehavior = [.fullScreenNone]
        }
    }

    // MARK: - Menu actions (reached through the responder chain)

    @objc func toggleKeepOnTop(_ sender: Any?) {
        model.isPinned.toggle()
    }

    @objc func changeNoteColor(_ sender: NSMenuItem) {
        guard let color = sender.representedObject as? NoteColor else { return }
        model.color = color
    }

    @objc func toggleTextStyle(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? TextStyle else { return }
        textView.toggle(style, using: textView.formatting)
    }

    /// Gives the selected text its own font, or, for "Same as Note", removes it.
    @objc func changeTextFont(_ sender: NSMenuItem) {
        let family = sender.representedObject as? String
        textView.changeFont(using: textView.formatting, actionName: "Font") { $0.family = family }
    }

    /// Gives the selected text its own size, or, for "Same as Note", removes it.
    @objc func changeTextSize(_ sender: NSMenuItem) {
        let size = sender.representedObject as? Double
        textView.changeFont(using: textView.formatting, actionName: "Text Size") { $0.size = size }
    }

    @objc func makeTextBigger(_ sender: Any?) {
        stepTextSize(larger: true)
    }

    @objc func makeTextSmaller(_ sender: Any?) {
        stepTextSize(larger: false)
    }

    private func stepTextSize(larger: Bool) {
        let size = FontSettings.nextStandardSize(from: font.size, larger: larger)
        // Landing on the default size goes back to following the default.
        model.font.size = size == settings.font.size ? nil : size
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(makeTextBigger(_:)):
            return FontSettings.nextStandardSize(from: font.size, larger: true) != font.size
        case #selector(makeTextSmaller(_:)):
            return FontSettings.nextStandardSize(from: font.size, larger: false) != font.size
        case #selector(toggleKeepOnTop(_:)):
            menuItem.state = model.isPinned ? .on : .off
        case #selector(changeNoteColor(_:)):
            menuItem.state = menuItem.representedObject as? NoteColor == model.color ? .on : .off
        case #selector(toggleTextStyle(_:)):
            guard let style = menuItem.representedObject as? TextStyle else { return false }
            menuItem.state = textView.selectionHas(style) ? .on : .off
        case #selector(changeTextFont(_:)):
            let families = textView.selectedFonts.map(\.family)
            menuItem.state = Self.state(of: menuItem.representedObject as? String, in: families)
        case #selector(changeTextSize(_:)):
            let sizes = textView.selectedFonts.map(\.size)
            menuItem.state = Self.state(of: menuItem.representedObject as? Double, in: sizes)
        default:
            break
        }
        return true
    }

    /// On when all of the selection uses `value`, mixed when only part of it does.
    private static func state<Value: Hashable>(of value: Value, in values: [Value]) -> NSControl.StateValue {
        guard values.contains(value) else { return .off }
        return Set(values).count == 1 ? .on : .mixed
    }

    // MARK: - NSTextViewDelegate

    func textDidChange(_ notification: Notification) {
        let text = textView.attributedString()
        model.setContent(text: text.string, styles: RichText.styleRuns(of: text), fontRuns: RichText.fontRuns(of: text))
    }

    /// Adds the note's own formatting choices to the right-click menu, in place of the standard
    /// Font submenu, whose choices a note wouldn't keep.
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        let fontMenuIndex = menu.items.firstIndex { item in
            item.submenu?.items.contains { $0.action == #selector(NSFontManager.addFontTrait(_:)) } ?? false
        }
        let insertionIndex: Int
        if let fontMenuIndex {
            menu.removeItem(at: fontMenuIndex)
            insertionIndex = fontMenuIndex
        } else {
            menu.insertItem(.separator(), at: 0)
            insertionIndex = 0
        }

        // Target this note directly: right-clicking a note doesn't make it the frontmost window.
        let items =
            TextStyle.allCases.map { $0.menuItem(target: self) }
            + [FontMenus.fontItem(target: self), FontMenus.sizeItem(target: self)]
        for (offset, item) in items.enumerated() {
            menu.insertItem(item, at: insertionIndex + offset)
        }
        return menu
    }

    // MARK: - NSTextStorageDelegate

    nonisolated func textStorage(
        _ textStorage: NSTextStorage,
        willProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        // Tidy up newly inserted text, such as a paste from a web page, so it matches the note's
        // look. Text being composed with an input method (for example, Chinese or accented
        // letters) is left alone until it is committed.
        guard editedMask.contains(.editedCharacters), editedRange.length > 0 else { return }
        // Text views only ever edit their text on the main thread.
        let richText: RichText? = MainActor.assumeIsolated {
            textView.hasMarkedText() ? nil : textView.formatting
        }
        richText?.normalize(textStorage, in: editedRange)
    }

    // MARK: - NSWindowDelegate

    func windowDidMove(_ notification: Notification) {
        recordFrame()
    }

    func windowDidResize(_ notification: Notification) {
        recordFrame()
    }

    private func recordFrame() {
        guard let frame = window?.frame else { return }
        model.frame = NoteFrame(frame)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if model.note.isBlank {
            isDeleting = true
            return true
        }
        confirmDeletion(in: sender)
        return false
    }

    func windowWillClose(_ notification: Notification) {
        guard isDeleting else { return }
        model.onChange = nil
        delegate?.noteWindowControllerDidDeleteNote(self)
    }

    private func confirmDeletion(in window: NSWindow) {
        let alert = NSAlert()
        alert.messageText = "Delete this note?"
        alert.informativeText = "This can’t be undone."
        alert.addButton(withTitle: "Delete").hasDestructiveAction = true
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn, let self else { return }
            isDeleting = true
            self.window?.close()
        }
    }
}
