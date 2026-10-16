import Foundation

/// The font every note is shown in.
public struct FontSettings: Equatable, Sendable {
    public static let sizeRange: ClosedRange<Double> = 9...72
    public static let standard = FontSettings(family: nil, size: defaultSize)

    private static let defaultSize: Double = 14
    private static let familyKey = "FontFamily"
    private static let sizeKey = "FontSize"

    /// A font family name such as "Helvetica Neue", or `nil` for the system font.
    public var family: String?
    /// Point size, kept within `sizeRange`.
    public var size: Double

    public init(family: String?, size: Double) {
        self.family = family
        self.size =
            size.isFinite
            ? min(max(size, Self.sizeRange.lowerBound), Self.sizeRange.upperBound)
            : Self.defaultSize
    }

    /// Reads the saved settings, using the standard value for anything missing or invalid.
    public init(store: some KeyValueStore) {
        let family = store.object(forKey: Self.familyKey) as? String
        // Accept text too: `defaults write` and command-line arguments store "16" as a string.
        let storedSize = store.object(forKey: Self.sizeKey)
        let size = storedSize as? Double ?? (storedSize as? String).flatMap(Double.init)
        self.init(family: family?.isEmpty == false ? family : nil, size: size ?? Self.defaultSize)
    }

    public func save(to store: some KeyValueStore) {
        if let family {
            store.set(family, forKey: Self.familyKey)
        } else {
            store.removeObject(forKey: Self.familyKey)
        }
        store.set(size, forKey: Self.sizeKey)
    }
}
