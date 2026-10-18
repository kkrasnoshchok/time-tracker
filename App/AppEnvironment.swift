import Foundation
import TimeTrackerCore

/// Builds the one persistent `TimeStore` the whole app shares.
@MainActor
enum AppEnvironment {
    static func makeStore() -> TimeStore {
        do {
            let directory = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("TimeTracker", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let container = try TimeStore.makeContainer(storeURL: directory.appendingPathComponent("store.sqlite"))
            let store = TimeStore(container: container, time: SystemTimeProvider())
            seedDefaultCategoriesIfEmpty(store)
            return store
        } catch {
            fatalError("Cannot open the time store: \(error)")
        }
    }

    /// First launch only: a few starter categories so the palette is usable immediately.
    private static func seedDefaultCategoriesIfEmpty(_ store: TimeStore) {
        guard store.categories().isEmpty else { return }
        let defaults = [("Работа", "#0A84FF"), ("Учёба", "#30D158"), ("Личное", "#FF9F0A")]
        for (name, color) in defaults {
            _ = try? store.addCategory(name: name, colorHex: color)
        }
    }
}
