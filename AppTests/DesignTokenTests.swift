import SwiftUI
import Testing
@testable import TimeTracker

struct DesignTokenTests {
    // Values copied by hand from DESIGN.md frontmatter.
    @Test(arguments: [
        (ColorToken.surfaceCanvas, "#F7F7F5"),
        (.surfaceCard, "#FFFFFF"),
        (.surfaceInset, "#EDECE7"),
        (.surfaceInput, "#EEEEEE"),
        (.textPrimary, "#1B0624"),
        (.textSecondary, "#766A7C"),
        (.textTertiary, "#898683"),
        (.textBody, "#444444"),
        (.actionPrimary, "#160F0C"),
        (.onActionPrimary, "#FFFFFF"),
        (.borderGhost, "#898683"),
        (.categoryClay, "#B4705A"),
        (.categoryOchre, "#B8964A"),
        (.categoryMoss, "#8A9A6A"),
        (.categoryLagoon, "#5F8A88"),
        (.categorySlate, "#6F86A0"),
        (.categoryPlum, "#8D6F8F"),
        (.categoryRose, "#B88A8A"),
        (.categoryTaupe, "#7A7570")
    ])
    func colorTokenHexMatchesDesign(token: ColorToken, hex: String) {
        #expect(token.hex == hex)
        #expect(Color(hex: token.hex).hexString == hex)
    }

    @Test func tokenTableCoversEveryColor() {
        #expect(ColorToken.allCases.count == 19)
    }

    @Test(arguments: [
        (TypeRole.timerDisplay, 32.0, 400, -0.03, 1.1),
        (.dayTotal, 28, 400, -0.03, 1.1),
        (.title, 20, 500, 0, 1.3),
        (.paletteInput, 20, 400, 0, 1.3),
        (.body, 15, 400, 0, 1.4),
        (.bodyEmphasis, 15, 500, 0, 1.4),
        (.caption, 13, 400, 0, 1.4),
        (.micro, 12, 400, 0, 1.2)
    ])
    func typeRoleMatchesDesign(role: TypeRole, size: Double, weight: Int, tracking: Double, line: Double) {
        #expect(role.size == size)
        #expect(role.weightValue == weight)
        #expect(role.tracking == tracking)
        #expect(role.lineHeight == line)
    }

    @Test(arguments: TypeRole.allCases)
    func typeRoleRules(role: TypeRole) {
        #expect(role.weightValue == 400 || role.weightValue == 500)
        let negative = role.tracking < 0
        #expect(negative == (role == .timerDisplay || role == .dayTotal))
    }

    @Test func spacingAndRadiiMatchDesign() {
        #expect([Space.x1, Space.x2, Space.x3, Space.x4, Space.x5, Space.x6, Space.x8, Space.x10] == [4, 8, 12, 16, 20, 24, 32, 40])
        #expect(Space.rowHeight == 44)
        #expect(Space.paletteFieldHeight == 60)
        #expect(Space.suggestionRowHeight == 40)
        #expect([Radius.input, Radius.row, Radius.card, Radius.panel, Radius.pill] == [8, 10, 16, 20, 9999])
    }

    @Test(arguments: [
        (HairlineVariant.standard, ColorSchemeContrast.standard, 0.05),
        (.palette, .standard, 0.10),
        (.standard, .increased, 0.30),
        (.palette, .increased, 0.40)
    ])
    func ringOpacityExact(variant: HairlineVariant, contrast: ColorSchemeContrast, expected: Double) {
        #expect(HairlineRing.opacity(variant: variant, contrast: contrast) == expected)
    }

    @Test(arguments: [HairlineVariant.standard, .palette])
    func increasedContrastIsStrictlyHigher(variant: HairlineVariant) {
        let normal = HairlineRing.opacity(variant: variant, contrast: .standard)
        let increased = HairlineRing.opacity(variant: variant, contrast: .increased)
        #expect(increased > normal)
    }

    @Test(arguments: [
        (CategoryTone.clay, "#B4705A"),
        (.ochre, "#B8964A"),
        (.moss, "#8A9A6A"),
        (.lagoon, "#5F8A88"),
        (.slate, "#6F86A0"),
        (.plum, "#8D6F8F"),
        (.rose, "#B88A8A"),
        (.taupe, "#7A7570")
    ])
    func toneHexMatchesDesign(tone: CategoryTone, hex: String) {
        #expect(tone.hex == hex)
        #expect(ColorToken.category(tone).hex == hex)
    }

    @Test(arguments: [
        (Color.surfaceCanvas, "#F7F7F5"),
        (.surfaceCard, "#FFFFFF"),
        (.surfaceInset, "#EDECE7"),
        (.surfaceInput, "#EEEEEE"),
        (.textPrimary, "#1B0624"),
        (.textSecondary, "#766A7C"),
        (.textTertiary, "#898683"),
        (.textBody, "#444444"),
        (.actionPrimary, "#160F0C"),
        (.onActionPrimary, "#FFFFFF"),
        (.borderGhost, "#898683")
    ])
    func colorAliasMatchesDesign(color: Color, hex: String) {
        #expect(color.hexString == hex)
    }
}
