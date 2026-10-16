public enum NoteColor: String, Codable, CaseIterable, Sendable {
    case yellow
    case pink
    case blue
    case green
    case purple
    case gray

    /// Falls back to yellow for colors this version doesn't know, such as ones added by a newer
    /// release, so a single unknown value never makes the whole notes file unreadable.
    public init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = NoteColor(rawValue: rawValue) ?? .yellow
    }
}
