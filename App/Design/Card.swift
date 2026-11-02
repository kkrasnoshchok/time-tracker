import SwiftUI

extension View {
    /// White container: radius 16, hairline ring, padding 16. Like a `<Card>`
    /// wrapper component in React, written as a modifier.
    func card() -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card)
        return padding(Space.x4)
            .background(Color.surfaceCard, in: shape)
            .hairlineRing(shape)
    }
}
