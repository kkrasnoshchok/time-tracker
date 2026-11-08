import Foundation
import TimeTrackerCore

/// Everything a Journal row shows, computed from plain values so it can be tested
/// without a view (like a selector that turns state into props).
struct EntryRowModel: Equatable {
    let start: Date
    let displayTitle: String
    let displayCategory: String
    let duration: TimeInterval
    let isRunning: Bool
    let isLong: Bool

    init(start: Date, end: Date?, title: String?, categoryName: String?, now: Date) {
        self.start = start
        displayTitle = title ?? EntryRowText.untitled
        displayCategory = categoryName ?? ""
        duration = (end ?? now).timeIntervalSince(start)
        isRunning = end == nil
        isLong = LongEntry.isLong(start: start, end: end, now: now)
    }

    init(entry: TimeEntry, now: Date) {
        self.init(
            start: entry.start, end: entry.end, title: entry.title,
            categoryName: entry.category?.name, now: now)
    }

    var accessibilityLabel: String {
        EntryRowText.accessibilityLabel(
            title: displayTitle == EntryRowText.untitled ? nil : displayTitle,
            category: displayCategory, duration: duration, isLong: isLong, isRunning: isRunning)
    }
}
