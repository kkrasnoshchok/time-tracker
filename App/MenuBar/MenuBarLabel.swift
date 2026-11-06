import Foundation
import TimeTrackerCore

/// Pure text for the menu bar item, kept out of the view so it can be tested.
enum MenuBarLabel {
    static let noCategory = "Без категории"
    static let idle = "Таймер не запущен"
    static let lessThanAMinute = "меньше минуты"

    /// Visible text while a timer runs: `Работа 12:05`.
    static func text(category: String?, elapsed: TimeInterval) -> String {
        "\(name(category)) \(DurationFormat.clock(elapsed))"
    }

    /// VoiceOver sentence: category and elapsed time, or the idle state.
    static func accessibilityLabel(category: String?, elapsed: TimeInterval?) -> String {
        guard let elapsed else { return idle }
        let spoken = elapsed < 60 ? lessThanAMinute : DurationFormat.short(elapsed)
        return "\(name(category)), \(spoken)"
    }

    private static func name(_ category: String?) -> String {
        guard let category, !category.isEmpty else { return noCategory }
        return category
    }
}
