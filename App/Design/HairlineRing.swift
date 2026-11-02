import SwiftUI

enum HairlineVariant: Sendable {
    case standard
    case palette
}

enum HairlineRing {
    /// Pure rule so it can be unit-tested without a view.
    static func opacity(variant: HairlineVariant, contrast: ColorSchemeContrast) -> Double {
        switch (variant, contrast) {
        case (.standard, .increased): 0.30
        case (.standard, _): 0.05
        case (.palette, .increased): 0.40
        case (.palette, _): 0.10
        }
    }
}

/// Draws a 1px black ring inside a shape.
///
/// `@Environment` reads a value from the surrounding view tree, like
/// `useContext` in React.
struct HairlineRingModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let variant: HairlineVariant
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content.overlay {
            shape.strokeBorder(.black.opacity(HairlineRing.opacity(variant: variant, contrast: contrast)), lineWidth: 1)
        }
    }
}

extension View {
    func hairlineRing<S: InsettableShape>(_ shape: S, variant: HairlineVariant = .standard) -> some View {
        modifier(HairlineRingModifier(shape: shape, variant: variant))
    }
}
