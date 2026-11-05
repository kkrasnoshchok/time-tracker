import Testing
@testable import TimeTracker

struct EntryRowTextTests {
    @Test func finishedShortEntryReadsTitleCategoryDuration() {
        let label = EntryRowText.accessibilityLabel(
            title: "Отчёт", category: "Работа", duration: 5400, isLong: false, isRunning: false)
        #expect(label == "Отчёт, Работа, 1 ч 30 мин")
    }

    @Test func longEntryReadsNoteWithDuration() {
        let label = EntryRowText.accessibilityLabel(
            title: "Отчёт", category: "Работа", duration: 9 * 3600, isLong: true, isRunning: false)
        #expect(label == "Отчёт, Работа, 9 ч, долго")
    }

    @Test func runningEntryGetsRunningCue() {
        let label = EntryRowText.accessibilityLabel(
            title: nil, category: nil, duration: 600, isLong: false, isRunning: true)
        #expect(label == "Без названия, 10 мин, идёт")
    }

    @Test func longRunningEntryReadsLongNoteBeforeRunningCue() {
        let label = EntryRowText.accessibilityLabel(
            title: "A", category: nil, duration: 9 * 3600, isLong: true, isRunning: true)
        #expect(label == "A, 9 ч, долго, идёт")
    }

    @Test func emptyCategoryIsSkipped() {
        let label = EntryRowText.accessibilityLabel(
            title: "A", category: "", duration: 60, isLong: false, isRunning: false)
        #expect(label == "A, 1 мин")
    }
}
