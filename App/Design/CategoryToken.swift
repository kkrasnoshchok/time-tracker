import SwiftUI

/// Pill with the category name on the tone mixed 22% over the card color. No dot.
/// Like a `<Tag color={tone}>{name}</Tag>` React component.
struct CategoryToken: View {
    let name: String
    let storedHex: String

    /// Share of the tone in the background, from the design contract.
    private static let tintFraction = 0.22

    private var background: Color {
        let tone = CategoryTone(storedHex: storedHex)
        return Color(hex: tone.tintedHex(over: ColorToken.surfaceCard.hex, fraction: Self.tintFraction))
    }

    var body: some View {
        Text(name)
            .typeRole(.bodyEmphasis)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, Space.x3)
            .padding(.vertical, 6) // 6 has no spacing token
            .background(background, in: Capsule())
            .accessibilityLabel(name)
    }
}
