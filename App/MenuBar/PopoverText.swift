import Foundation
import TimeTrackerCore

/// Pure strings for the popover, kept out of the views so they can be tested.
enum PopoverText {
    static let idleTitle = "Таймер не запущен"
    static let noCategory = "Без категории"

    static func idleHint(paletteShortcut: String?) -> String {
        guard let paletteShortcut, !paletteShortcut.isEmpty else {
            return "Хоткей палитры не задан. Задайте его в настройках."
        }
        return "Начните запись: \(paletteShortcut)"
    }

    static func categoryName(_ name: String?) -> String {
        guard let name, !name.isEmpty else { return noCategory }
        return name
    }

    /// «долго» for a running entry, from the Core rule (`LongEntry`); nil when it is not long.
    static func longNote(start: Date, now: Date) -> String? {
        LongEntry.isLong(start: start, end: nil, now: now) ? EntryRowText.longNote : nil
    }

    /// VoiceOver reading of the elapsed time, with «долго» when it applies.
    static func elapsedAccessibilityLabel(elapsed: TimeInterval, isLong: Bool) -> String {
        let time = DurationFormat.short(elapsed)
        return isLong ? "\(time), \(EntryRowText.longNote)" : time
    }
}
