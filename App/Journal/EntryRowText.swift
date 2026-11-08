import Foundation
import TimeTrackerCore

/// Pure text for a Journal row, kept out of the view so it can be tested.
enum EntryRowText {
    static let longNote = "долго"
    static let untitled = "Без названия"

    /// One VoiceOver sentence: title, category, duration, then «долго» and «идёт» when they apply.
    static func accessibilityLabel(
        title: String?,
        category: String?,
        duration: TimeInterval,
        isLong: Bool,
        isRunning: Bool
    ) -> String {
        var parts = [title ?? untitled]
        if let category, !category.isEmpty { parts.append(category) }
        parts.append(DurationFormat.short(duration))
        if isLong { parts.append(longNote) }
        if isRunning { parts.append("идёт") }
        return parts.joined(separator: ", ")
    }
}
