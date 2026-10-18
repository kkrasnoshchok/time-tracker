import Foundation

/// Journal filter. All conditions that are set must hold. `from` is inclusive, `to` exclusive,
/// and both compare against the entry's start.
public struct EntryFilter: Equatable {
    public var category: UUID?
    public var tag: UUID?
    public var text: String
    public var from: Date?
    public var to: Date?

    public init(
        category: UUID? = nil,
        tag: UUID? = nil,
        text: String = "",
        from: Date? = nil,
        to: Date? = nil
    ) {
        self.category = category
        self.tag = tag
        self.text = text
        self.from = from
        self.to = to
    }

    public func matches(_ entry: TimeEntry) -> Bool {
        if let category, entry.category?.id != category { return false }
        if let tag, !entry.tagList.contains(where: { $0.id == tag }) { return false }
        if let from, entry.start < from { return false }
        if let to, entry.start >= to { return false }
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if needle.isEmpty { return true }
        let haystacks = [entry.title, entry.notes].compactMap { $0 } + entry.tagList.map(\.name)
        return haystacks.contains { $0.lowercased().contains(needle) }
    }
}
