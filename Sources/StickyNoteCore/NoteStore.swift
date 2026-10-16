import Foundation

public enum NoteStoreError: Error, LocalizedError {
    /// The file exists but isn't valid notes JSON.
    case corrupted(underlying: any Error)
    /// The file was written by a newer version of the app, using a format this version can't read.
    case unsupportedVersion(Int)

    public var errorDescription: String? {
        switch self {
        case .corrupted(let underlying):
            "The notes file is damaged: \(underlying.localizedDescription)"
        case .unsupportedVersion(let version):
            "The notes file uses format version \(version), which this version of StickyNote can't read."
        }
    }
}

/// Reads and writes all notes as a single versioned JSON file.
public struct NoteStore: Sendable {
    /// Increase this whenever the file format changes in a way older versions can't read.
    public static let currentVersion = 1

    /// `~/Library/Application Support/StickyNote/notes.json`
    public static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(components: "StickyNote", "notes.json")
    }

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Returns the saved notes, or an empty list if nothing has been saved yet.
    public func load() throws -> [Note] {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return []
        }

        let decoder = Self.makeDecoder()
        // Check the version on its own first, so a newer format is reported as such
        // instead of as a generic decoding failure.
        let header: FileHeader
        do {
            header = try decoder.decode(FileHeader.self, from: data)
        } catch {
            throw NoteStoreError.corrupted(underlying: error)
        }
        guard header.version <= Self.currentVersion else {
            throw NoteStoreError.unsupportedVersion(header.version)
        }

        do {
            return try decoder.decode(FileContents.self, from: data).notes
        } catch {
            throw NoteStoreError.corrupted(underlying: error)
        }
    }

    /// Writes all notes, replacing the file atomically so a crash can't leave it half-written.
    public func save(_ notes: [Note]) throws {
        let contents = FileContents(version: Self.currentVersion, notes: notes)
        let data = try Self.makeEncoder().encode(contents)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    /// Renames an unreadable notes file so that later saves can never overwrite it.
    ///
    /// - Returns: The file's new location, e.g. `notes.unreadable-20261016-142530.json`.
    public func moveAside(date: Date = Date()) throws -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"

        let baseName = fileURL.deletingPathExtension().lastPathComponent
        let backupURL = fileURL.deletingLastPathComponent()
            .appending(component: "\(baseName).unreadable-\(formatter.string(from: date)).json")
        try FileManager.default.moveItem(at: fileURL, to: backupURL)
        return backupURL
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private struct FileHeader: Decodable {
    let version: Int
}

private struct FileContents: Codable {
    let version: Int
    let notes: [Note]
}
