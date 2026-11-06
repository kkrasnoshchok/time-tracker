import Foundation
import Testing
import TimeTrackerCore
@testable import TimeTracker

@MainActor
struct AppModelMenuBarTests {
    private struct FixedTime: TimeProvider {
        let date: Date
        func now() -> Date { date }
    }

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeModel() throws -> (AppModel, TimeStore) {
        let store = try TimeStore.inMemory(time: FixedTime(date: now))
        return (AppModel(store: store), store)
    }

    @Test func idleHasNoTitleAndIdleSpokenLabel() throws {
        let (model, _) = try makeModel()
        #expect(model.menuBarTitle == nil)
        #expect(model.menuBarAccessibilityLabel == "Таймер не запущен")
    }

    @Test func runningPassesCategoryAndElapsedToBothLabels() throws {
        let (model, store) = try makeModel()
        let work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        try store.startTimer(
            category: work, title: nil, tags: [], startedAt: now.addingTimeInterval(-725))
        model.refresh()
        #expect(model.menuBarTitle == "Работа 12:05")
        #expect(model.menuBarAccessibilityLabel == "Работа, 12 мин")
    }

    @Test func runningUnderAMinuteIsSpokenAsLessThanAMinute() throws {
        let (model, store) = try makeModel()
        let work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        try store.startTimer(
            category: work, title: nil, tags: [], startedAt: now.addingTimeInterval(-30))
        model.refresh()
        #expect(model.menuBarTitle == "Работа 0:30")
        #expect(model.menuBarAccessibilityLabel == "Работа, меньше минуты")
    }
}
