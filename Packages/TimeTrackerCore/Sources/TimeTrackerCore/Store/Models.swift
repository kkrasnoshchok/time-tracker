import Foundation
import SwiftData

// All stored properties have defaults and relationships are optional, so the schema stays CloudKit-compatible.

@Model
public final class EntryCategory {
    public var id: UUID = UUID()
    public var name: String = ""
    public var colorHex: String = "#8E8E93"
    public var sortOrder: Int = 0
    @Relationship(deleteRule: .nullify, inverse: \TimeEntry.category)
    public var entries: [TimeEntry]? = []

    public init(name: String, colorHex: String, sortOrder: Int) {
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
}

@Model
public final class Tag {
    public var id: UUID = UUID()
    public var name: String = ""
    @Relationship(inverse: \TimeEntry.tags)
    public var entries: [TimeEntry]? = []

    public init(name: String) {
        self.name = name
    }
}

@Model
public final class TimeEntry {
    public var id: UUID = UUID()
    public var start: Date = Date(timeIntervalSinceReferenceDate: 0)
    /// `nil` while the timer is running.
    public var end: Date?
    public var category: EntryCategory?
    public var tags: [Tag]? = []
    public var title: String?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        start: Date,
        end: Date? = nil,
        category: EntryCategory? = nil,
        title: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.category = category
        self.title = title
        self.notes = notes
    }

    public var tagList: [Tag] { tags ?? [] }
}
