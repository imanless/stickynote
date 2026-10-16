import Foundation

/// A single sticky note, as it is stored on disk.
public struct Note: Codable, Equatable, Identifiable, Sendable {
    /// Longest window title derived from a note's text, including the trailing ellipsis.
    public static let maxTitleLength = 40

    public let id: UUID
    public var text: String
    /// Bold, italic and other formatting applied to ranges of `text`.
    public var styles: [StyleRun]
    /// Fonts and sizes chosen for ranges of `text`, on top of the note's `font`.
    public var fontRuns: [FontRun]
    public var color: NoteColor
    /// The note's own font choices, on top of the app-wide default.
    public var font: FontOverride
    public var frame: NoteFrame
    /// Whether the note floats above other applications' windows.
    public var isPinned: Bool
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        text: String = "",
        styles: [StyleRun] = [],
        fontRuns: [FontRun] = [],
        color: NoteColor = .yellow,
        font: FontOverride = FontOverride(),
        frame: NoteFrame,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.styles = styles
        self.fontRuns = fontRuns
        self.color = color
        self.font = font
        self.frame = frame
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt ?? createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        // Notes saved before formatting existed have no styles. Styles this version doesn't
        // know (for example, added by a newer release) are skipped rather than failing the note.
        styles =
            try container.decodeIfPresent([SkippingInvalid<StyleRun>].self, forKey: .styles)?
            .compactMap(\.value) ?? []
        fontRuns =
            try container.decodeIfPresent([SkippingInvalid<FontRun>].self, forKey: .fontRuns)?
            .compactMap(\.value) ?? []
        color = try container.decode(NoteColor.self, forKey: .color)
        // Missing in notes saved before per-note fonts; an unreadable value falls back to the
        // default font rather than making the whole note unreadable.
        font = (try? container.decodeIfPresent(FontOverride.self, forKey: .font)) ?? FontOverride()
        frame = try container.decode(NoteFrame.self, forKey: .frame)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
    }

    /// The first non-empty line of the note, shortened to fit a window title.
    /// Empty when the note contains only whitespace.
    public var title: String {
        let firstLine =
            text
            .split(whereSeparator: \.isNewline)
            .lazy
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty } ?? ""

        guard firstLine.count > Self.maxTitleLength else { return firstLine }
        return String(firstLine.prefix(Self.maxTitleLength - 1)) + "…"
    }

    /// Whether the note has no visible content, so deleting it loses nothing.
    public var isBlank: Bool {
        text.allSatisfy(\.isWhitespace)
    }
}

/// Decodes to `nil` instead of throwing, so one unreadable element doesn't fail a whole array.
private struct SkippingInvalid<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}
