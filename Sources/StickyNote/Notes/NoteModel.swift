import Foundation
import Observation
import StickyNoteCore

/// The live state of one open note. The SwiftUI title bar controls observe its color, font and
/// pin state; `onChange` lets the window controller react to every edit (update the window, save).
@MainActor
@Observable
final class NoteModel {
    let id: UUID
    let createdAt: Date

    var color: NoteColor {
        didSet { onChange?() }
    }
    var font: FontOverride {
        didSet { onChange?() }
    }
    var isPinned: Bool {
        didSet { onChange?() }
    }

    // Not observed: no SwiftUI view shows these, and the frame changes continuously
    // while the window is dragged.
    @ObservationIgnored private(set) var text: String
    @ObservationIgnored private(set) var styles: [StyleRun]
    @ObservationIgnored private(set) var fontRuns: [FontRun]
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
        fontRuns = note.fontRuns
        color = note.color
        font = note.font
        isPinned = note.isPinned
        frame = note.frame
        modifiedAt = note.modifiedAt
    }

    func setContent(text: String, styles: [StyleRun], fontRuns: [FontRun]) {
        guard text != self.text || styles != self.styles || fontRuns != self.fontRuns else { return }
        self.text = text
        self.styles = styles
        self.fontRuns = fontRuns
        modifiedAt = Date()
        onChange?()
    }

    var note: Note {
        Note(
            id: id,
            text: text,
            styles: styles,
            fontRuns: fontRuns,
            color: color,
            font: font,
            frame: frame,
            isPinned: isPinned,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}
