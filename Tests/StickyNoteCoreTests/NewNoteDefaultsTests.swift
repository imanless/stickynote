import StickyNoteCore
import Testing

struct NewNoteDefaultsTests {
    private let store = InMemoryStore()

    @Test func newNotesArePinnedUnlessChanged() {
        #expect(NewNoteDefaults(store: store).isPinned)
    }

    @Test func turningPinningOffIsSaved() {
        NewNoteDefaults(isPinned: false).save(to: store)

        #expect(!NewNoteDefaults(store: store).isPinned)
    }

    @Test(arguments: [("NO", false), ("false", false), ("0", false), ("YES", true), ("true", true)])
    func valueWrittenAsTextIsUnderstood(text: String, expected: Bool) {
        store.values["PinNewNotes"] = text
        #expect(NewNoteDefaults(store: store).isPinned == expected)
    }

    @Test func unreadableValueFallsBackToPinned() {
        store.values["PinNewNotes"] = "maybe"
        #expect(NewNoteDefaults(store: store).isPinned)
    }
}
