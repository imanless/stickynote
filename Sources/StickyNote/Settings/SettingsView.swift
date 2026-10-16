import AppKit
import StickyNoteCore
import SwiftUI

/// Lets the user choose how new notes start out, and the font and text size of every note.
struct SettingsView: View {
    private static let standardSizes: [Double] = [10, 11, 12, 13, 14, 16, 18, 20, 24, 28, 32, 36, 48]

    @Bindable var settings: AppSettings
    private let fontFamilies = NSFontManager.shared.availableFontFamilies.sorted()

    var body: some View {
        Form {
            Section("New Notes") {
                Toggle(isOn: $settings.newNotes.isPinned) {
                    Text("Keep new notes on top")
                    Text("New notes float above other apps. Use a note’s pin button to change it.")
                }
            }

            Section("Text") {
                Picker("Font", selection: $settings.font.family) {
                    Text("System Font").tag(String?.none)
                    Divider()
                    ForEach(fontFamilies, id: \.self) { family in
                        Text(family).tag(String?.some(family))
                    }
                }

                Picker("Size", selection: $settings.font.size) {
                    ForEach(sizes, id: \.self) { size in
                        Text("\(size.formatted()) pt").tag(size)
                    }
                }
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
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// The standard sizes, plus the current one if it was set to something else.
    private var sizes: [Double] {
        Set(Self.standardSizes + [settings.font.size]).sorted()
    }
}
