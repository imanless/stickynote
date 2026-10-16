import StickyNoteCore
import SwiftUI

/// The color and pin buttons shown at the right of a note's title bar.
struct NoteTitlebarControls: View {
    @Bindable var model: NoteModel

    var body: some View {
        HStack(spacing: 4) {
            Menu {
                Picker("Color", selection: $model.color) {
                    ForEach(NoteColor.allCases, id: \.self) { color in
                        Text(color.displayName).tag(color)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } label: {
                Image(systemName: "paintpalette")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Change Color")
            .accessibilityLabel("Change Color")

            Button {
                model.isPinned.toggle()
            } label: {
                Image(systemName: model.isPinned ? "pin.fill" : "pin")
                    .foregroundStyle(model.isPinned ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
            .help(model.isPinned ? "Stop Keeping on Top" : "Keep on Top of Other Windows")
            .accessibilityLabel("Keep on Top")
            .accessibilityValue(model.isPinned ? "On" : "Off")
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
    }
}
