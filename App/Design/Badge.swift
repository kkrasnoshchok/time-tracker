import SwiftUI

/// Neutral information pill: `surfaceInset` fill, `micro` text.
struct Badge: View {
    private let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .typeRole(.micro)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 10) // 3x10 has no spacing token
            .padding(.vertical, 3)
            .background(Color.surfaceInset, in: Capsule())
    }
}
