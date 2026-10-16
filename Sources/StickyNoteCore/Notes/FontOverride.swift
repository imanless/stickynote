/// One note's own font choices. Anything left `nil` follows the app-wide `FontSettings`, so a
/// note that only changes its size still follows the default font, and the other way round.
public struct FontOverride: Codable, Equatable, Sendable {
    /// The `family` of a note that uses the system font even when the default is another font.
    public static let systemFamily = ""

    /// A font family name, `systemFamily`, or `nil` to follow the default.
    public var family: String?
    /// A point size, or `nil` to follow the default.
    public var size: Double?

    public init(family: String? = nil, size: Double? = nil) {
        self.family = family
        self.size = size
    }

    /// The font the note uses when the app-wide default is `defaults`.
    public func applied(to defaults: FontSettings) -> FontSettings {
        let resolvedFamily: String?
        switch family {
        case nil: resolvedFamily = defaults.family
        case Self.systemFamily?: resolvedFamily = nil
        case let name?: resolvedFamily = name
        }
        return FontSettings(family: resolvedFamily, size: size ?? defaults.size)
    }
}
