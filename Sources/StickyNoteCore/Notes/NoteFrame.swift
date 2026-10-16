/// A window rectangle in screen coordinates, with AppKit's bottom-left origin.
///
/// Stored as plain numbers (rather than `CGRect`) so the notes file stays readable JSON.
public struct NoteFrame: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var maxX: Double { x + width }
    public var maxY: Double { y + height }

    /// Whether enough of this frame overlaps one of `screens` for the user to see it and drag it.
    ///
    /// Used to rescue notes saved on a display that has since been disconnected.
    public func isReachable(on screens: [NoteFrame], minimumVisibleLength: Double = 40) -> Bool {
        screens.contains { screen in
            let overlapWidth = min(maxX, screen.maxX) - max(x, screen.x)
            let overlapHeight = min(maxY, screen.maxY) - max(y, screen.y)
            return overlapWidth >= minimumVisibleLength && overlapHeight >= minimumVisibleLength
        }
    }
}
