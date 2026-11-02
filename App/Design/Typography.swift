import SwiftUI

/// The eight text styles of the design system.
enum TypeRole: CaseIterable, Sendable {
    case timerDisplay, dayTotal, title, paletteInput, body, bodyEmphasis, caption, micro

    var size: Double {
        switch self {
        case .timerDisplay: 32
        case .dayTotal: 28
        case .title, .paletteInput: 20
        case .body, .bodyEmphasis: 15
        case .caption: 13
        case .micro: 12
        }
    }

    /// CSS-style numeric weight; only 400 and 500 are allowed.
    var weightValue: Int {
        switch self {
        case .title, .bodyEmphasis: 500
        default: 400
        }
    }

    /// Letter spacing in em. Negative only for the two large numerals.
    var tracking: Double {
        switch self {
        case .timerDisplay, .dayTotal: -0.03
        default: 0
        }
    }

    /// Unitless CSS-style line height multiplier.
    var lineHeight: Double {
        switch self {
        case .timerDisplay, .dayTotal: 1.1
        case .title, .paletteInput: 1.3
        case .body, .bodyEmphasis, .caption: 1.4
        case .micro: 1.2
        }
    }

    var fontWeight: Font.Weight { weightValue == 500 ? .medium : .regular }
}

/// A `ViewModifier` is a reusable wrapper around a view, like a higher-order
/// component in React. `@ScaledMetric` is a number that grows with the user's
/// Dynamic Type setting, like a `rem` value that follows browser font size.
struct TypeRoleModifier: ViewModifier {
    let role: TypeRole
    @ScaledMetric(relativeTo: .body) private var scale: Double = 1

    func body(content: Content) -> some View {
        let size = role.size * scale
        content
            .font(.system(size: size, weight: role.fontWeight))
            .tracking(size * role.tracking)
            // SwiftUI has no line-height; this approximates it.
            .lineSpacing(size * (role.lineHeight - 1))
    }
}

extension View {
    /// Applies a design-system text style, e.g. `Text("x").typeRole(.body)`.
    func typeRole(_ role: TypeRole) -> some View {
        modifier(TypeRoleModifier(role: role))
    }

    /// Fixed-width digits so a ticking timer does not jitter.
    func tabularFigures() -> some View {
        monospacedDigit()
    }
}
