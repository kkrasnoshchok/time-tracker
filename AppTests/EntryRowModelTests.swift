import Foundation
import Testing
@testable import TimeTracker

struct EntryRowModelTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func model(
        end: TimeInterval? = nil, now: TimeInterval, title: String? = "Отчёт", category: String? = "Работа"
    ) -> EntryRowModel {
        EntryRowModel(
            start: start,
            end: end.map { start.addingTimeInterval($0) },
            title: title,
            categoryName: category,
            now: start.addingTimeInterval(now))
    }

    @Test func finishedEntryUsesStartToEndAsDuration() {
        let row = model(end: 5400, now: 99_999)
        #expect(row.duration == 5400)
        #expect(!row.isRunning)
    }

    @Test func runningEntryUsesNowAsEnd() {
        let row = model(now: 600)
        #expect(row.duration == 600)
        #expect(row.isRunning)
    }

    @Test func longRuleStartsAtEightHours() {
        #expect(!model(now: 8 * 3600 - 60).isLong)
        #expect(model(now: 8 * 3600).isLong)
    }

    @Test func missingTitleFallsBackToUntitled() {
        #expect(model(now: 60, title: nil).displayTitle == "Без названия")
        #expect(model(now: 60).displayTitle == "Отчёт")
    }

    @Test func missingCategoryGivesEmptyName() {
        #expect(model(now: 60, category: nil).displayCategory == "")
    }

    @Test func accessibilityLabelMatchesRowText() {
        let row = model(now: 9 * 3600)
        #expect(row.accessibilityLabel == "Отчёт, Работа, 9 ч, долго, идёт")
    }
}
