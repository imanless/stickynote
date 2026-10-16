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
            onChange?()
        }
    }

    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        font = FontSettings(store: defaults)
    }
}

extension FontSettings {
    /// The regular face of the chosen family, or the system font if that family isn't installed.
    @MainActor
    var nsFont: NSFont {
        family.flatMap { NSFontManager.shared.font(withFamily: $0, traits: [], weight: 5, size: size) }
            ?? .systemFont(ofSize: size)
    }
}
