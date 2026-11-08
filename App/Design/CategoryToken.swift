import SwiftUI

/// Pill with the category name on the tone mixed 22% over the card color. No dot.
/// Like a `<Tag color={tone}>{name}</Tag>` React component.
struct CategoryToken: View {
    let name: String
    let storedHex: String

    /// Share of the tone in the background, from the design contract.
    static let tintFraction = 0.22

    /// Pill background as a hex string, so tests can pin it without rendering.
    static func backgroundHex(storedHex: String) -> String {
        CategoryTone(storedHex: storedHex).tintedHex(over: ColorToken.surfaceCard.hex, fraction: tintFraction)
    }

    private var background: Color {
        Color(hex: Self.backgroundHex(storedHex: storedHex))
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
