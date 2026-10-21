import AppKit

/// Adds notes to Apple's Notes app through the share extension Notes provides to every app, which
/// shows Notes' own panel for saving them. Unlike scripting Notes, this needs no permission.
@MainActor
enum AppleNotes {
    private static let serviceName = NSSharingService.Name("com.apple.Notes.SharingExtension")

    /// Notes' app icon, or `nil` if Notes isn't available.
    static let icon = makeService()?.image

    static func makeService() -> NSSharingService? {
        NSSharingService(named: serviceName)
    }
}
