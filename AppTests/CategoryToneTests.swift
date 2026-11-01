import Testing
import TimeTrackerCore
@testable import TimeTracker

struct CategoryToneTests {
    @Test(arguments: [
        ("#0A84FF", CategoryTone.slate),
        ("#30D158", .moss),
        ("#FF9F0A", .clay),
        ("#FF453A", .rose),
        ("#BF5AF2", .plum),
        ("#64D2FF", .lagoon),
        ("#FFD60A", .ochre),
        ("#AC8E68", .taupe)
    ])
    func coreDefaultHexMapsToItsTone(hex: String, tone: CategoryTone) {
        #expect(CategoryTone(storedHex: hex) == tone)
        #expect(CategoryTone(storedHex: hex.lowercased()) == tone)
    }

    @Test func eightDefaultsStayDistinct() {
        let hexes = ["#0A84FF", "#30D158", "#FF9F0A", "#FF453A", "#BF5AF2", "#64D2FF", "#FFD60A", "#AC8E68"]
        #expect(Set(hexes.map { CategoryTone(storedHex: $0) }).count == 8)
    }

    @Test(arguments: CategoryTone.allCases)
    func toneHexMapsToItself(tone: CategoryTone) {
        #expect(CategoryTone(storedHex: tone.hex) == tone)
    }

    @Test(arguments: [
        ("#B47059", CategoryTone.clay),
        ("#B89649", .ochre),
        ("#8A9A69", .moss),
        ("#5F8A8B", .lagoon),
        ("#6F86A3", .slate),
        ("#8D6F8C", .plum),
        ("#B88A89", .rose),
        ("#7A7573", .taupe)
    ])
    func hexNearAToneGoesToThatTone(hex: String, tone: CategoryTone) {
        #expect(CategoryTone(storedHex: hex) == tone)
    }

    @Test func unknownHexGoesToNearestTone() {
        // Oklab distance from pure red: clay 0.167, rose 0.208, ochre 0.226.
        #expect(CategoryTone(storedHex: "#FF0000") == .clay)
    }

    @Test func nearestUsesOklabNotRGBDistance() {
        // Plain RGB distance puts #BE6205 nearest to ochre; Oklab puts it nearest to clay.
        #expect(CategoryTone(storedHex: "#BE6205") == .clay)
    }

    @MainActor
    @Test func everyCoreCategoryColorGetsItsOwnTone() {
        let tones = PaletteViewModel.categoryColors.map { CategoryTone(storedHex: $0) }
        #expect(Set(tones).count == PaletteViewModel.categoryColors.count)
    }

    @Test func exactTieGoesToEarlierToneInOrder() {
        // Duplicate-distance case: distance is measured to the tone's own hex,
        // so a tie is only reachable through the ordering rule itself.
        #expect(CategoryTone.tieBreakOrder == [.clay, .ochre, .moss, .lagoon, .slate, .plum, .rose, .taupe])
        #expect(CategoryTone.nearest(toDistances: [.moss: 1, .clay: 1, .rose: 2]) == .clay)
    }

    @Test(arguments: ["", "#FFF", "red", "#GGGGGG", "0A84FF00", "#0A84F"])
    func invalidHexIsTaupe(hex: String) {
        #expect(CategoryTone(storedHex: hex) == .taupe)
    }
}
