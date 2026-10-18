import Foundation
import SwiftData

/// The only door to persisted data. UI and view models talk to this, never to SwiftData directly.
@MainActor
public final class TimeStore {
    let container: ModelContainer
    let time: TimeProvider

    var context: ModelContext { container.mainContext }

    public init(container: ModelContainer, time: TimeProvider) {
        self.container = container
        self.time = time
    }

    public static func inMemory(time: TimeProvider) throws -> TimeStore {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: EntryCategory.self, Tag.self, TimeEntry.self,
            configurations: configuration
        )
        return TimeStore(container: container, time: time)
    }

    // MARK: Categories

    public func categories() -> [EntryCategory] {
        let descriptor = FetchDescriptor<EntryCategory>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? context.fetch(descriptor)) ?? []
    }

    @discardableResult
    public func addCategory(name: String, colorHex: String) throws(StoreError) -> EntryCategory {
        let cleaned = try validatedName(name, excluding: nil)
        let nextOrder = (categories().map(\.sortOrder).max() ?? -1) + 1
        let category = EntryCategory(name: cleaned, colorHex: colorHex, sortOrder: nextOrder)
        context.insert(category)
        try save()
        return category
    }

    public func renameCategory(_ category: EntryCategory, to name: String) throws(StoreError) {
        category.name = try validatedName(name, excluding: category)
        try save()
    }

    /// Deletes a category. If it still has entries, they must be moved to another category first.
    public func deleteCategory(_ category: EntryCategory, movingEntriesTo destination: EntryCategory?) throws(StoreError) {
        let entries = entries(in: category)
        if !entries.isEmpty {
            guard let destination, destination !== category else { throw .categoryHasEntries }
            for entry in entries { entry.category = destination }
        }
        context.delete(category)
        try save()
    }

    func entries(in category: EntryCategory) -> [TimeEntry] {
        let id = category.id
        let descriptor = FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.category?.id == id })
        return (try? context.fetch(descriptor)) ?? []
    }

    func entryCount(in category: EntryCategory) -> Int {
        entries(in: category).count
    }

    // MARK: Tags

    public func tags() -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Finds a tag ignoring case, creating it on first use.
    public func tag(named name: String) -> Tag {
        let wanted = name.lowercased()
        if let existing = tags().first(where: { $0.name.lowercased() == wanted }) { return existing }
        let tag = Tag(name: name)
        context.insert(tag)
        return tag
    }

    // MARK: Helpers

    func save() throws(StoreError) {
        do {
            try context.save()
        } catch {
            throw .saveFailed(String(describing: error))
        }
    }

    private func validatedName(_ name: String, excluding: EntryCategory?) throws(StoreError) -> String {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw .emptyName }
        let lowered = cleaned.lowercased()
        let taken = categories().contains { $0 !== excluding && $0.name.lowercased() == lowered }
        if taken { throw .duplicateName }
        return cleaned
    }
}
