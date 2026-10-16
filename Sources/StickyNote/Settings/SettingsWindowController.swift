import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    init(settings: AppSettings, updater: AppUpdater) {
        let window = NSWindow(
            contentViewController: NSHostingController(rootView: SettingsView(settings: settings, updater: updater)))
        window.title = "Settings"
        window.styleMask = [.titled, .closable]
        window.tabbingMode = .disallowed
        window.isRestorable = false
        super.init(window: window)
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
