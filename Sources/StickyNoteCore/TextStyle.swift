/// Character formatting that can be applied to part of a note's text.
public enum TextStyle: String, Codable, CaseIterable, Sendable {
    case bold
    case italic
    case underline
    case strikethrough
}

/// One style applied to a range of a note's text.
///
/// Ranges are measured in UTF-16 code units, the same way `NSString` and `NSRange` count,
/// so they map directly onto the text system without conversion.
public struct StyleRun: Codable, Equatable, Sendable {
    public var style: TextStyle
    public var location: Int
    public var length: Int

    public init(style: TextStyle, location: Int, length: Int) {
        self.style = style
        self.location = location
        self.length = length
    }

    public var end: Int { location + length }

    /// Cleans up runs so they are safe to apply to a text of `textLength` UTF-16 code units:
    /// clamps them to the text, drops empty ones, and merges touching or overlapping runs of
    /// the same style. The result is sorted by style (in declaration order), then location, so
    /// saved files are stable.
    public static func normalized(_ runs: [StyleRun], textLength: Int) -> [StyleRun] {
        let clamped = runs.compactMap { run -> StyleRun? in
            let location = min(max(run.location, 0), textLength)
            let length = min(max(run.length, 0), textLength - location)
            return length > 0 ? StyleRun(style: run.style, location: location, length: length) : nil
        }
        let sorted = clamped.sorted {
            ($0.style.sortOrder, $0.location) < ($1.style.sortOrder, $1.location)
        }

        var merged: [StyleRun] = []
        for run in sorted {
            if let last = merged.last, last.style == run.style, run.location <= last.end {
                merged[merged.count - 1].length = max(last.end, run.end) - last.location
            } else {
                merged.append(run)
            }
        }
        return merged
    }
}

extension TextStyle {
    fileprivate var sortOrder: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
