import Foundation

/// The parts of `UserDefaults` that settings need, so tests can use an in-memory store
/// instead of writing to the user's preferences.
public protocol KeyValueStore {
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
    func removeObject(forKey key: String)
}

extension UserDefaults: KeyValueStore {}
