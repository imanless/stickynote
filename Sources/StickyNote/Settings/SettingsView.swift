import AppKit
import StickyNoteCore
import SwiftUI

/// Lets the user choose how new notes start out, the default font and text size, and how updates
/// are checked.
struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Bindable var updater: AppUpdater
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

    var body: some View {
        Form {
            Section("New Notes") {
                Toggle(isOn: $settings.newNotes.isPinned) {
                    Text("Keep new notes on top")
                    Text("New notes float above other apps. Use a note’s pin button to change it.")
                }
            }

            Section {
                Picker("Font", selection: $settings.font.family) {
                    Text("System Font").tag(String?.none)
                    Divider()
                    ForEach(FontSettings.installedFamilies, id: \.self) { family in
                        Text(family).tag(String?.some(family))
                    }
                }

                Picker("Size", selection: $settings.font.size) {
                    ForEach(FontSettings.sizeChoices(including: settings.font.size), id: \.self) { size in
                        Text("\(size.formatted()) pt").tag(size)
                    }
                }
            } header: {
                Text("Text")
            } footer: {
                Text("Used by every note that doesn’t have its own font. To change one note, use its palette button.")
                    .foregroundStyle(.secondary)
            }

            Section("Preview") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("The quick brown fox jumps over the lazy dog.")
                    Text("**Bold**, *italic*, and ~~crossed out~~ text.")
                }
                .font(Font(settings.font.nsFont as CTFont))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(12)
                .background(Color(nsColor: NoteColor.yellow.nsColor), in: .rect(cornerRadius: 6))
            }

            Section("Updates") {
                Toggle("Check for updates automatically", isOn: $updater.checksAutomatically)
                LabeledContent("Version \(appVersion ?? "in development")") {
                    Button("Check Now") { updater.checkForUpdates() }
                        .disabled(!updater.canCheckForUpdates)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }
}
