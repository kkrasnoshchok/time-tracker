import Foundation
import Observation

/// State behind the Journal window: filtered, day-grouped entries plus save/delete and category actions.
@MainActor
@Observable
public final class JournalViewModel {
    public var filter = EntryFilter() {
        didSet { reload() }
    }
    public private(set) var groups: [DayGroup] = []
    public private(set) var categories: [EntryCategory] = []
    public private(set) var tags: [Tag] = []

    private let store: TimeStore
    private let calendar: Calendar

    public init(store: TimeStore, calendar: Calendar = .current) {
        self.store = store
        self.calendar = calendar
        reload()
    }

    public func reload() {
        categories = store.categories()
        tags = store.tags()
        groups = DayGrouping.group(filteredEntries(), calendar: calendar, now: store.time.now())
    }

    // MARK: Entries

    /// Creates an entry (`entry == nil`) or updates the given one from the draft.
    @discardableResult
    public func save(
        _ draft: EntryDraft,
        to entry: TimeEntry?,
        allowOverlap: Bool = false
    ) throws(StoreError) -> TimeEntry {
        guard let id = draft.categoryID, let category = categories.first(where: { $0.id == id }) else {
            throw .notFound
        }
        let span: TimeSpan
        do {
            span = try TimeSpan(start: draft.start, end: draft.end)
        } catch {
            throw .endBeforeStart
        }
        let tagNames = TagInput.parse(draft.tags)
        let saved: TimeEntry
        if let entry {
            try store.update(
                entry, span: span, category: category, title: draft.title, tags: tagNames,
                notes: draft.notes, allowOverlap: allowOverlap
            )
            saved = entry
        } else {
            saved = try store.addEntry(
                span: span, category: category, title: draft.title, tags: tagNames,
                notes: draft.notes, allowOverlap: allowOverlap
            )
        }
        reload()
        return saved
    }

    public func delete(_ entry: TimeEntry) throws(StoreError) {
        try store.delete(entry)
        reload()
    }

    /// Entries matching the current filter in export format. `TimeStore.entries` returns oldest first.
    public func exportRows() -> [ExportRow] {
        let now = store.time.now()
        return filteredEntries().map { ExportRow(entry: $0, now: now) }
    }

    // MARK: Categories

    @discardableResult
    public func addCategory(name: String, colorHex: String) throws(StoreError) -> EntryCategory {
        defer { reload() }
        return try store.addCategory(name: name, colorHex: colorHex)
    }

    public func renameCategory(_ category: EntryCategory, to name: String) throws(StoreError) {
        defer { reload() }
        try store.renameCategory(category, to: name)
    }

    public func setColor(_ colorHex: String, for category: EntryCategory) throws(StoreError) {
        defer { reload() }
        try store.setColor(colorHex, for: category)
    }

    public func reorderCategories(_ ordered: [EntryCategory]) throws(StoreError) {
        defer { reload() }
        try store.reorderCategories(ordered)
    }

    public func deleteCategory(
        _ category: EntryCategory,
        movingEntriesTo destination: EntryCategory?
    ) throws(StoreError) {
        defer { reload() }
        try store.deleteCategory(category, movingEntriesTo: destination)
    }

    // MARK: Private

    private func filteredEntries() -> [TimeEntry] {
        store.entries(from: .distantPast, to: .distantFuture).filter(filter.matches)
    }
}
