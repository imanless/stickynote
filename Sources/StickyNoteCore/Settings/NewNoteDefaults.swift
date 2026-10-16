/// How newly created notes start out.
public struct NewNoteDefaults: Equatable, Sendable {
    public static let standard = NewNoteDefaults(isPinned: true)

    private static let isPinnedKey = "PinNewNotes"

    /// Whether new notes start out kept on top of other windows.
    public var isPinned: Bool

    public init(isPinned: Bool) {
        self.isPinned = isPinned
    }

    /// Reads the saved settings, using the standard value for anything missing or invalid.
    public init(store: some KeyValueStore) {
        self.init(isPinned: Self.bool(from: store.object(forKey: Self.isPinnedKey)) ?? Self.standard.isPinned)
    }

    public func save(to store: some KeyValueStore) {
        store.set(isPinned, forKey: Self.isPinnedKey)
    }

    // Command-line arguments such as `-PinNewNotes NO` arrive as text.
    private static func bool(from value: Any?) -> Bool? {
        switch value {
        case let bool as Bool:
            bool
        case let text as String:
            switch text.lowercased() {
            case "yes", "true", "1": true
            case "no", "false", "0": false
            default: nil
            }
        default:
            nil
        }
    }
}
