import Foundation
import StickyNoteCore
import Testing

/// Stands in for `UserDefaults`, so tests never touch the user's preferences.
private final class InMemoryStore: KeyValueStore {
    var values: [String: Any] = [:]

    func object(forKey key: String) -> Any? { values[key] }
    func set(_ value: Any?, forKey key: String) { values[key] = value }
    func removeObject(forKey key: String) { values[key] = nil }
}

struct FontSettingsTests {
    private let store = InMemoryStore()

    @Test func nothingSavedMeansStandardSettings() {
        #expect(FontSettings(store: store) == .standard)
        #expect(FontSettings.standard.family == nil)
    }

    @Test func savedSettingsLoadBack() {
        let settings = FontSettings(family: "Helvetica Neue", size: 18)

        settings.save(to: store)

        #expect(FontSettings(store: store) == settings)
    }

    @Test func switchingBackToTheSystemFontIsSaved() {
        FontSettings(family: "Helvetica Neue", size: 18).save(to: store)

        FontSettings(family: nil, size: 18).save(to: store)

        #expect(FontSettings(store: store).family == nil)
    }

    @Test func emptyFamilyMeansSystemFont() {
        store.values["FontFamily"] = ""
        #expect(FontSettings(store: store).family == nil)
    }

    @Test func sizeWrittenAsTextIsUnderstood() {
        store.values["FontSize"] = "20"
        #expect(FontSettings(store: store).size == 20)
    }

    @Test func invalidSavedSizeFallsBackToStandard() {
        store.values["FontSize"] = "big"
        #expect(FontSettings(store: store).size == FontSettings.standard.size)
    }

    @Test(arguments: [(1.0, 9.0), (500.0, 72.0), (Double.nan, 14.0), (16.0, 16.0)])
    func sizeIsKeptInRange(requested: Double, expected: Double) {
        #expect(FontSettings(family: nil, size: requested).size == expected)
    }
}
