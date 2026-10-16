import StickyNoteCore
import SwiftUI

/// The color and pin buttons shown at the right of a note's title bar.
struct NoteTitlebarControls: View {
    @Bindable var model: NoteModel
    @State private var isChoosingColor = false

    var body: some View {
        HStack(spacing: 4) {
            Button {
                isChoosingColor.toggle()
            } label: {
                Image(systemName: "paintpalette")
            }
            .buttonStyle(.borderless)
            .help("Change Color")
            .accessibilityLabel("Change Color")
            .popover(isPresented: $isChoosingColor, arrowEdge: .bottom) {
                ColorSwatches(selection: $model.color) { isChoosingColor = false }
            }

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
