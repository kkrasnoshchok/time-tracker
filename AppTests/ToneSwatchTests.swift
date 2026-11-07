import Testing
@testable import TimeTracker

struct ToneSwatchTests {
    @Test func currentToneIsSelectedByMapping() {
        // A bright stored hex selects the tone it maps to.
        #expect(ToneSwatch.isSelected(.clay, storedHex: "#FF9F0A"))
        #expect(!ToneSwatch.isSelected(.ochre, storedHex: "#FF9F0A"))
    }

    @Test func exactlyOneSwatchSelected() {
        let selected = CategoryTone.allCases.filter { ToneSwatch.isSelected($0, storedHex: "#6F86A0") }
        #expect(selected == [.slate])
    }

    @Test func accessibilityNameHasToneAndState() {
        #expect(ToneSwatch.accessibilityName(.moss, isSelected: false) == "Мох")
        #expect(ToneSwatch.accessibilityName(.moss, isSelected: true) == "Мох, выбран")
    }

    @Test func everyToneHasAName() {
        #expect(Set(CategoryTone.allCases.map { ToneSwatch.displayName($0) }).count == 8)
    }
}
