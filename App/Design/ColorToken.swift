import SwiftUI

/// Every color of the design system, named by role (not by look).
///
/// TS analogy: a `const colors = { surfaceCanvas: "#F7F7F5", ... } as const`
/// plus a union type of its keys. `CaseIterable` is like `Object.keys(colors)`.
enum ColorToken: CaseIterable, Sendable {
    case surfaceCanvas, surfaceCard, surfaceInset, surfaceInput
    case textPrimary, textSecondary, textTertiary, textBody
    case actionPrimary, onActionPrimary, borderGhost
    case categoryClay, categoryOchre, categoryMoss, categoryLagoon
    case categorySlate, categoryPlum, categoryRose, categoryTaupe

    /// `#RRGGBB`, the single place where hex values live.
    var hex: String {
        switch self {
        case .surfaceCanvas: "#F7F7F5"
        case .surfaceCard: "#FFFFFF"
        case .surfaceInset: "#EDECE7"
        case .surfaceInput: "#EEEEEE"
        case .textPrimary: "#1B0624"
        case .textSecondary: "#766A7C"
        case .textTertiary: "#898683"
        case .textBody: "#444444"
        case .actionPrimary: "#160F0C"
        case .onActionPrimary: "#FFFFFF"
        case .borderGhost: "#898683"
        case .categoryClay: "#B4705A"
        case .categoryOchre: "#B8964A"
        case .categoryMoss: "#8A9A6A"
        case .categoryLagoon: "#5F8A88"
        case .categorySlate: "#6F86A0"
        case .categoryPlum: "#8D6F8F"
        case .categoryRose: "#B88A8A"
        case .categoryTaupe: "#7A7570"
        }
    }

    var color: Color { Color(hex: hex) }

    /// The category token that backs a tone.
    static func category(_ tone: CategoryTone) -> ColorToken {
        switch tone {
        case .clay: .categoryClay
        case .ochre: .categoryOchre
        case .moss: .categoryMoss
        case .lagoon: .categoryLagoon
        case .slate: .categorySlate
        case .plum: .categoryPlum
        case .rose: .categoryRose
        case .taupe: .categoryTaupe
        }
    }
}

/// `extension Color` adds members to an existing type, like declaring extra
/// methods on `Array.prototype`, but type-safe and scoped to the module.
/// `static let` is a class-level constant, like `static readonly` in TS.
extension Color {
    static let surfaceCanvas = ColorToken.surfaceCanvas.color
    static let surfaceCard = ColorToken.surfaceCard.color
    static let surfaceInset = ColorToken.surfaceInset.color
    static let surfaceInput = ColorToken.surfaceInput.color
    static let textPrimary = ColorToken.textPrimary.color
    static let textSecondary = ColorToken.textSecondary.color
    static let textTertiary = ColorToken.textTertiary.color
    static let textBody = ColorToken.textBody.color
    static let actionPrimary = ColorToken.actionPrimary.color
    static let onActionPrimary = ColorToken.onActionPrimary.color
    static let borderGhost = ColorToken.borderGhost.color
}
