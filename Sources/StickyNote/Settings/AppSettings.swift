import AppKit
import Observation
import StickyNoteCore

/// App-wide preferences, saved in the user's defaults and edited in the Settings window.
@MainActor
@Observable
final class AppSettings {
    var font: FontSettings {
        didSet {
            guard font != oldValue else { return }
            font.save(to: defaults)
            onFontChange?()
        }
    }

    /// Read when a note is created, so changing it needs no callback.
    var newNotes: NewNoteDefaults {
        didSet {
            guard newNotes != oldValue else { return }
            newNotes.save(to: defaults)
        }
    }

    @ObservationIgnored var onFontChange: (() -> Void)?
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        font = FontSettings(store: defaults)
        newNotes = NewNoteDefaults(store: defaults)
    }
}

extension FontSettings {
    /// The font families installed on this Mac, for font menus.
    @MainActor static let installedFamilies = NSFontManager.shared.availableFontFamilies.sorted()

    var familyName: String {
        family ?? "System Font"
    }

    /// The regular face of the chosen family, or the system font if that family isn't installed.
    var nsFont: NSFont {
        family.flatMap { NSFontManager.shared.font(withFamily: $0, traits: [], weight: 5, size: size) }
            ?? .systemFont(ofSize: size)
    }
}
