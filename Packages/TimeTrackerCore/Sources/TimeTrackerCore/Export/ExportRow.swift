import Foundation

/// One flattened entry in the export format. Column order: start, end, duration_seconds,
/// category, tags, title, notes.
public struct ExportRow: Equatable, Sendable {
    public var start: Date
    /// `nil` while the timer is running.
    public var end: Date?
    public var durationSeconds: Int
    public var category: String
    /// Sorted by name, so exports are stable between runs.
    public var tags: [String]
    public var title: String
    public var notes: String

    public init(
        start: Date,
        end: Date?,
        durationSeconds: Int,
        category: String,
        tags: [String],
        title: String,
        notes: String
    ) {
        self.start = start
        self.end = end
        self.durationSeconds = durationSeconds
        self.category = category
        self.tags = tags
        self.title = title
        self.notes = notes
    }

    /// A running entry lasts until `now`.
    public init(entry: TimeEntry, now: Date) {
        self.init(
            start: entry.start,
            end: entry.end,
            durationSeconds: Int(max(0, (entry.end ?? now).timeIntervalSince(entry.start))),
            category: entry.category?.name ?? "",
            tags: entry.tagList.map(\.name).sorted(),
            title: entry.title ?? "",
            notes: entry.notes ?? ""
        )
    }
}
