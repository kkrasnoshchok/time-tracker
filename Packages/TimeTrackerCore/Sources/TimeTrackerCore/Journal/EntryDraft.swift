import Foundation

/// The editable form of an entry: what the Journal's detail panel and "add entry" sheet bind to.
public struct EntryDraft: Equatable, Sendable {
    public var start: Date
    /// `nil` means the entry is still running.
    public var end: Date?
    public var categoryID: UUID?
    public var title: String
    /// Free text such as `#a #b`; see `TagInput`.
    public var tags: String
    public var notes: String

    public init(
        start: Date,
        end: Date?,
        categoryID: UUID?,
        title: String = "",
        tags: String = "",
        notes: String = ""
    ) {
        self.start = start
        self.end = end
        self.categoryID = categoryID
        self.title = title
        self.tags = tags
        self.notes = notes
    }

    public init(entry: TimeEntry) {
        self.init(
            start: entry.start,
            end: entry.end,
            categoryID: entry.category?.id,
            title: entry.title ?? "",
            tags: TagInput.format(entry.tagList.map(\.name).sorted()),
            notes: entry.notes ?? ""
        )
    }

    /// Starting point for "add entry": the last hour, ending now.
    public static func blank(now: Date, categoryID: UUID?) -> EntryDraft {
        EntryDraft(start: now.addingTimeInterval(-3600), end: now, categoryID: categoryID)
    }
}
