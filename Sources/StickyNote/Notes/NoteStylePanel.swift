import StickyNoteCore
import SwiftUI

/// The panel behind a note's palette button: the note's color, its own font and size, and a
/// button to add it to Apple's Notes app.
struct NoteStylePanel: View {
    @Bindable var model: NoteModel
    /// Read for the app-wide defaults, which the "Default" choices show.
    let settings: AppSettings
    let addToNotes: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ColorSwatches(selection: $model.color)

            Divider()

            Form {
                Picker("Font", selection: $model.font.family) {
                    Text("Default (\(settings.font.familyName))").tag(String?.none)
                    Divider()
                    Text("System Font").tag(String?.some(FontOverride.systemFamily))
                    ForEach(FontSettings.installedFamilies, id: \.self) { family in
                        Text(family).tag(String?.some(family))
                    }
                }

                Picker("Size", selection: $model.font.size) {
                    Text("Default (\(settings.font.size.formatted()) pt)").tag(Double?.none)
                    Divider()
                    ForEach(FontSettings.sizeChoices(including: model.font.size), id: \.self) { size in
                        Text("\(size.formatted()) pt").tag(Double?.some(size))
                    }
                }
            }
            .padding(12)

            if let notesIcon = AppleNotes.icon {
                Divider()

                Button(action: addToNotes) {
                    Label {
                        Text("Add to Notes…")
                    } icon: {
                        Image(nsImage: notesIcon)
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
        }
        .frame(width: 280)
    }
}
