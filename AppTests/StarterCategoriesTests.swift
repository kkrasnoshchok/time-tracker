import Foundation
import Testing
import TimeTrackerCore
@testable import TimeTracker

@MainActor
struct StarterCategoriesTests {
    private struct FixedTime: TimeProvider {
        func now() -> Date { Date(timeIntervalSince1970: 1_800_000_000) }
    }

    @Test func emptyStoreGetsThreeStarterCategoriesWithTones() throws {
        let store = try TimeStore.inMemory(time: FixedTime())
        AppEnvironment.seedDefaultCategoriesIfEmpty(store)
        let categories = store.categories()
        #expect(categories.map(\.name) == ["Работа", "Учёба", "Личное"])
        #expect(categories.map { CategoryTone(storedHex: $0.colorHex) } == [.slate, .moss, .clay])
        #expect(categories.map(\.colorHex) == [CategoryTone.slate.hex, CategoryTone.moss.hex, CategoryTone.clay.hex])
    }

    @Test func existingCategoriesAreLeftAlone() throws {
        let store = try TimeStore.inMemory(time: FixedTime())
        _ = try store.addCategory(name: "Своя", colorHex: CategoryTone.plum.hex)
        AppEnvironment.seedDefaultCategoriesIfEmpty(store)
        #expect(store.categories().map(\.name) == ["Своя"])
    }
}
