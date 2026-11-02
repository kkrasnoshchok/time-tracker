import Testing
@testable import TimeTracker

struct CategoryTintTests {
    @Test(arguments: [
        (CategoryTone.clay, "#FFFFFF", 0.22, "#EFE0DB"),
        (CategoryTone.clay, "#FFFFFF", 0.0, "#FFFFFF"),
        (CategoryTone.clay, "#FFFFFF", 1.0, "#B4705A"),
        (CategoryTone.slate, "#FFFFFF", 1.0, "#6F86A0"),
        // Non-white base: catches swapped from/to channels.
        (CategoryTone.clay, "#000000", 0.5, "#5A382D"),
        // Fraction is clamped to 0...1.
        (CategoryTone.clay, "#FFFFFF", 2.0, "#B4705A"),
        (CategoryTone.clay, "#FFFFFF", -1.0, "#FFFFFF"),
        // Lowercase base is accepted.
        (CategoryTone.clay, "#ffffff", 0.0, "#FFFFFF"),
        // Invalid base falls back to the tone itself.
        (CategoryTone.clay, "zzz", 0.22, "#B4705A")
    ])
    func tintMixesToneOverBase(tone: CategoryTone, base: String, fraction: Double, expected: String) {
        #expect(tone.tintedHex(over: base, fraction: fraction) == expected)
    }
}

struct CategoryTokenTests {
    // Pins the design contract: tone at 22% over the card white, for a stored default hex.
    @Test func backgroundIsToneAt22PercentOverCard() {
        #expect(CategoryToken.backgroundHex(storedHex: "#FF9F0A") == "#EFE0DB")
        #expect(CategoryToken.tintFraction == 0.22)
    }

    @Test func unknownStoredHexFallsBackToTaupeTint() {
        #expect(CategoryToken.backgroundHex(storedHex: "") == CategoryTone.taupe.tintedHex(over: "#FFFFFF", fraction: 0.22))
    }
}
