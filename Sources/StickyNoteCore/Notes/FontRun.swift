/// A font or size of its own for a range of a note's text. Whatever it leaves `nil` follows the
/// note's font, so a word that only has its own size changes font along with the rest of the note.
///
/// Ranges are measured in UTF-16 code units, like `StyleRun`'s.
public struct FontRun: Codable, Equatable, Sendable {
    public var font: FontOverride
    public var location: Int
    public var length: Int

    public init(font: FontOverride, location: Int, length: Int) {
        self.font = font
        self.location = location
        self.length = length
    }

    public var end: Int { location + length }

    /// Cleans up runs so they are safe to apply to a text of `textLength` UTF-16 code units:
    /// clamps them to the text, drops empty runs and runs that change nothing, and merges
    /// touching or overlapping runs with the same font. Sorted by location, so saved files are
    /// stable. Where runs with different fonts overlap, the later one is applied last and wins.
    public static func normalized(_ runs: [FontRun], textLength: Int) -> [FontRun] {
        let clamped = runs.compactMap { run -> FontRun? in
            let location = min(max(run.location, 0), textLength)
            let length = min(max(run.length, 0), textLength - location)
            guard length > 0, run.font != FontOverride() else { return nil }
            return FontRun(font: run.font, location: location, length: length)
        }
        // Ties keep their original order, which decides which of two overlapping runs wins.
        let sorted = clamped.enumerated()
            .sorted { ($0.element.location, $0.offset) < ($1.element.location, $1.offset) }
            .map(\.element)

        var merged: [FontRun] = []
        for run in sorted {
            if let last = merged.last, last.font == run.font, run.location <= last.end {
                merged[merged.count - 1].length = max(last.end, run.end) - last.location
            } else {
                merged.append(run)
            }
        }
        return merged
    }
}
