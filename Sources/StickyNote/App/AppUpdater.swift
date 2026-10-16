import AppKit
import Combine
import Sparkle

/// Finds and installs new versions using Sparkle.
///
/// Every release publishes a feed of available versions (`SUFeedURL` in Info.plist). Sparkle only
/// accepts a feed and an update signed with the private key matching `SUPublicEDKey`.
@MainActor
@Observable
final class AppUpdater {
    /// Mirrors Sparkle's own setting, so SwiftUI can bind to it.
    var checksAutomatically: Bool {
        didSet {
            guard controller.updater.automaticallyChecksForUpdates != checksAutomatically else { return }
            controller.updater.automaticallyChecksForUpdates = checksAutomatically
        }
    }
    private(set) var canCheckForUpdates = false

    @ObservationIgnored private let controller: SPUStandardUpdaterController
    @ObservationIgnored private var observations: [AnyCancellable] = []

    init() {
        // Builds run with `swift run` have no Info.plist, so there is nothing to update.
        let isConfigured = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil
        controller = SPUStandardUpdaterController(
            startingUpdater: isConfigured,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        checksAutomatically = controller.updater.automaticallyChecksForUpdates

        // Sparkle changes these on the main thread.
        let updater = controller.updater
        observations = [
            updater.publisher(for: \.canCheckForUpdates).sink { [weak self] value in
                MainActor.assumeIsolated { self?.canCheckForUpdates = value }
            },
            updater.publisher(for: \.automaticallyChecksForUpdates).sink { [weak self] value in
                MainActor.assumeIsolated { self?.checksAutomatically = value }
            },
        ]
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }

    /// A "Check for Updates…" item that Sparkle disables while a check is running.
    func makeMenuItem() -> NSMenuItem {
        let item = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        item.target = controller
        return item
    }
}
