import Foundation
import Observation
import StickyNoteCore

/// The live state of one open note. The SwiftUI title bar controls observe its color and pin
/// state; `onChange` lets the window controller react to every edit (update the window, save).
@MainActor
@Observable
final class NoteModel {
    let id: UUID
    let createdAt: Date

    var color: NoteColor {
        didSet { onChange?() }
    }
    var isPinned: Bool {
        didSet { onChange?() }
    }

    // Not observed: no SwiftUI view shows these, and the frame changes continuously
    // while the window is dragged.
    @ObservationIgnored private(set) var text: String
    @ObservationIgnored private(set) var styles: [StyleRun]
    @ObservationIgnored var frame: NoteFrame {
        didSet { onChange?() }
    }
    @ObservationIgnored private(set) var modifiedAt: Date
    @ObservationIgnored var onChange: (() -> Void)?

    init(note: Note) {
        id = note.id
        createdAt = note.createdAt
        text = note.text
        styles = note.styles
        color = note.color
        isPinned = note.isPinned
        frame = note.frame
        modifiedAt = note.modifiedAt
    }

    func setContent(text: String, styles: [StyleRun]) {
        guard text != self.text || styles != self.styles else { return }
        self.text = text
        self.styles = styles
        modifiedAt = Date()
        onChange?()
    }

    var note: Note {
        Note(
            id: id,
            text: text,
            styles: styles,
            color: color,
            frame: frame,
            isPinned: isPinned,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}
