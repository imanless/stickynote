import StickyNoteCore
import SwiftUI

/// A row of paper colors to pick from, with a checkmark on the current one.
struct ColorSwatches: View {
    @Binding var selection: NoteColor

    var body: some View {
        HStack(spacing: 8) {
            ForEach(NoteColor.allCases, id: \.self) { color in
                Button {
                    selection = color
                } label: {
                    swatch(for: color)
                }
                .buttonStyle(.plain)
                .help(color.displayName)
                .accessibilityLabel(color.displayName)
                .accessibilityAddTraits(color == selection ? .isSelected : [])
            }
        }
        .padding(10)
    }

    private func swatch(for color: NoteColor) -> some View {
        Circle()
            .fill(Color(nsColor: color.nsColor))
            .strokeBorder(Color.primary.opacity(0.25), lineWidth: 1)
            .overlay {
                if color == selection {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black.opacity(0.7))
                }
            }
            .frame(width: 24, height: 24)
            .contentShape(Circle())
    }
}
