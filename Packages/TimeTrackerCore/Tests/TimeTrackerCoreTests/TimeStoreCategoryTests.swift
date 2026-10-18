import Foundation
import Testing
@testable import TimeTrackerCore

@MainActor
struct TimeStoreCategoryTests {
    private let time = TestTimeProvider(at(12))

    private func makeStore() throws -> TimeStore {
        try TimeStore.inMemory(time: time)
    }

    /// Inserts an entry directly, because the entry API arrives in a later task.
    private func insertEntry(_ store: TimeStore, in category: EntryCategory) {
        store.context.insert(TimeEntry(start: at(9), end: at(10), category: category))
        try? store.context.save()
    }

    @Test func addCategoryAssignsIncreasingSortOrder() throws {
        let store = try makeStore()
        let work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        let study = try store.addCategory(name: "Учёба", colorHex: "#30D158")
        #expect(work.sortOrder == 0)
        #expect(study.sortOrder == 1)
        #expect(store.categories().map(\.name) == ["Работа", "Учёба"])
    }

    @Test func categoryNameIsTrimmed() throws {
        let store = try makeStore()
        let category = try store.addCategory(name: "  Работа  ", colorHex: "#0A84FF")
        #expect(category.name == "Работа")
    }

    @Test func emptyCategoryNameIsRejected() throws {
        let store = try makeStore()
        #expect(throws: StoreError.emptyName) {
            try store.addCategory(name: "   ", colorHex: "#0A84FF")
        }
        #expect(store.categories().isEmpty)
    }

    @Test func duplicateCategoryNameIsRejectedCaseInsensitively() throws {
        let store = try makeStore()
        try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        #expect(throws: StoreError.duplicateName) {
            try store.addCategory(name: "работа", colorHex: "#30D158")
        }
        #expect(store.categories().count == 1)
    }

    @Test func renameChangesNameAndKeepsIdentity() throws {
        let store = try makeStore()
        let work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        let id = work.id
        try store.renameCategory(work, to: "Дело")
        #expect(store.categories().map(\.name) == ["Дело"])
        #expect(store.categories().first?.id == id)
    }

    @Test func renameToExistingNameIsRejected() throws {
        let store = try makeStore()
        try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        let study = try store.addCategory(name: "Учёба", colorHex: "#30D158")
        #expect(throws: StoreError.duplicateName) {
            try store.renameCategory(study, to: "РАБОТА")
        }
        #expect(study.name == "Учёба")
    }

    @Test func renameToOwnNameWithDifferentCaseIsAllowed() throws {
        let store = try makeStore()
        let work = try store.addCategory(name: "работа", colorHex: "#0A84FF")
        try store.renameCategory(work, to: "Работа")
        #expect(work.name == "Работа")
    }

    @Test func deleteEmptyCategorySucceeds() throws {
        let store = try makeStore()
        let work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        try store.deleteCategory(work, movingEntriesTo: nil)
        #expect(store.categories().isEmpty)
    }

    @Test func deleteCategoryWithEntriesWithoutDestinationThrows() throws {
        let store = try makeStore()
        let work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        insertEntry(store, in: work)
        #expect(throws: StoreError.categoryHasEntries) {
            try store.deleteCategory(work, movingEntriesTo: nil)
        }
        #expect(store.categories().count == 1)
        #expect(store.entryCount(in: work) == 1)
    }

    @Test func deleteCategoryMovingEntriesToItselfIsRejected() throws {
        let store = try makeStore()
        let work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        insertEntry(store, in: work)
        #expect(throws: StoreError.categoryHasEntries) {
            try store.deleteCategory(work, movingEntriesTo: work)
        }
        #expect(store.entryCount(in: work) == 1)
    }

    @Test func deleteCategoryWithDestinationMovesEntries() throws {
        let store = try makeStore()
        let work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        let study = try store.addCategory(name: "Учёба", colorHex: "#30D158")
        insertEntry(store, in: work)
        insertEntry(store, in: work)
        try store.deleteCategory(work, movingEntriesTo: study)
        #expect(store.categories().map(\.name) == ["Учёба"])
        #expect(store.entryCount(in: study) == 2)
    }

    @Test func tagLookupIsCaseInsensitiveAndReusesInstance() throws {
        let store = try makeStore()
        let first = store.tag(named: "ClientX")
        let second = store.tag(named: "clientx")
        #expect(first === second)
        #expect(first.name == "ClientX")
        #expect(store.tags().count == 1)
    }
}
