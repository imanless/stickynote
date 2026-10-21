import StickyNoteCore
import SwiftUI

/// The style and pin buttons shown at the right of a note's title bar.
struct NoteTitlebarControls: View {
    @Bindable var model: NoteModel
    let settings: AppSettings
    let addToNotes: () -> Void
    @State private var isShowingStyle = false

    var body: some View {
        HStack(spacing: 4) {
            Button {
                isShowingStyle.toggle()
            } label: {
                Image(systemName: "paintpalette")
            }
            .buttonStyle(.borderless)
            .help("Color and Font")
            .accessibilityLabel("Color and Font")
            .popover(isPresented: $isShowingStyle, arrowEdge: .bottom) {
                NoteStylePanel(model: model, settings: settings) {
                    isShowingStyle = false
                    addToNotes()
                }
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
