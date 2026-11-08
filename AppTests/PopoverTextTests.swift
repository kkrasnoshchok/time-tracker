import Foundation
import Testing
@testable import TimeTracker

struct PopoverTextTests {
    @Test func idleHintNamesThePaletteHotkey() {
        #expect(PopoverText.idleHint(paletteShortcut: "⌃⌥T") == "Начните запись: ⌃⌥T")
    }

    @Test func idleHintWithoutShortcutPointsToSettings() {
        #expect(PopoverText.idleHint(paletteShortcut: nil) == "Хоткей палитры не задан. Задайте его в настройках.")
        #expect(PopoverText.idleHint(paletteShortcut: "") == "Хоткей палитры не задан. Задайте его в настройках.")
    }

    @Test func missingCategoryFallsBackToPlaceholder() {
        #expect(PopoverText.categoryName(nil) == "Без категории")
        #expect(PopoverText.categoryName("") == "Без категории")
        #expect(PopoverText.categoryName("Работа") == "Работа")
    }

    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func runningUnderEightHoursHasNoLongNote() {
        let now = start.addingTimeInterval(7 * 3600 + 59 * 60)
        #expect(PopoverText.longNote(start: start, now: now) == nil)
    }

    @Test func runningEightHoursGetsLongNote() {
        let now = start.addingTimeInterval(8 * 3600)
        #expect(PopoverText.longNote(start: start, now: now) == "долго")
    }

    @Test func runningAcrossMidnightKeepsLongNote() {
        let now = start.addingTimeInterval(26 * 3600)
        #expect(PopoverText.longNote(start: start, now: now) == "долго")
    }

    @Test func elapsedAccessibilityLabelAddsLongNoteOnlyWhenLong() {
        #expect(PopoverText.elapsedAccessibilityLabel(elapsed: 5400, isLong: false) == "1 ч 30 мин")
        #expect(PopoverText.elapsedAccessibilityLabel(elapsed: 30_000, isLong: true) == "8 ч 20 мин, долго")
    }
}
