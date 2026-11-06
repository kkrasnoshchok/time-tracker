import Testing
@testable import TimeTracker

struct MenuBarLabelTests {
    @Test func runningTextIsCategoryAndClock() {
        #expect(MenuBarLabel.text(category: "Работа", elapsed: 725) == "Работа 12:05")
    }

    @Test func runningTextOverAnHourShowsHours() {
        #expect(MenuBarLabel.text(category: "Работа", elapsed: 3725) == "Работа 1:02:05")
    }

    @Test func missingCategoryFallsBackWithoutLeadingSpace() {
        #expect(MenuBarLabel.text(category: nil, elapsed: 725) == "Без категории 12:05")
        #expect(MenuBarLabel.text(category: "", elapsed: 725) == "Без категории 12:05")
    }

    @Test func accessibilityRunningNamesCategoryAndElapsed() {
        #expect(MenuBarLabel.accessibilityLabel(category: "Работа", elapsed: 5400) == "Работа, 1 ч 30 мин")
    }

    @Test func accessibilityIdleSaysNothingRuns() {
        #expect(MenuBarLabel.accessibilityLabel(category: nil, elapsed: nil) == "Таймер не запущен")
    }

    @Test func accessibilityUnderAMinuteSaysLessThanAMinute() {
        #expect(MenuBarLabel.accessibilityLabel(category: "Работа", elapsed: 0) == "Работа, меньше минуты")
        #expect(MenuBarLabel.accessibilityLabel(category: "Работа", elapsed: 59) == "Работа, меньше минуты")
        #expect(MenuBarLabel.accessibilityLabel(category: "Работа", elapsed: 60) == "Работа, 1 мин")
    }

    @Test func accessibilityMissingCategoryUsesFallback() {
        #expect(MenuBarLabel.accessibilityLabel(category: nil, elapsed: 5400) == "Без категории, 1 ч 30 мин")
    }
}
