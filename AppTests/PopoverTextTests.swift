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
}
