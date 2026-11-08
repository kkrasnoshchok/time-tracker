import SwiftUI

/// Which of the two button looks to draw.
enum ButtonKind: Sendable {
    case primary
    case ghost
}

/// The visual shell of a button. It reads `isEnabled` and `isFocused` from the
/// environment (like `useContext` in React); a `ButtonStyle` itself only gets
/// `isPressed`, so this small wrapper view does the environment reads.
struct ButtonShell<Label: View>: View {
    let kind: ButtonKind
    let isPressed: Bool
    let label: Label
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        ButtonShellBody(
            kind: kind,
            appearance: ButtonAppearance.resolve(isEnabled: isEnabled, isPressed: isPressed, isFocused: isFocused),
            label: label
        )
        // Hide the system focus ring so only our custom 2px ring shows.
        .focusEffectDisabled()
    }
}

/// Draws the pill for a resolved appearance. Split out so the gallery can
/// force a state (pressed, focused) that cannot be triggered in a preview.
struct ButtonShellBody<Label: View>: View {
    let kind: ButtonKind
    let appearance: ButtonAppearance
    let label: Label

    var body: some View {
        label
            .typeRole(.caption)
            .foregroundStyle(kind == .primary ? Color.onActionPrimary : Color.textPrimary)
            .padding(.horizontal, Space.x4)
            .padding(.vertical, Space.x2)
            .frame(minHeight: 24)
            .background { fill }
            .overlay { outline }
            .opacity(appearance.opacity)
            .overlay { focusRing }
            .contentShape(Capsule())
    }

    @ViewBuilder private var fill: some View {
        if kind == .primary {
            Capsule().fill(Color.actionPrimary)
        }
    }

    @ViewBuilder private var outline: some View {
        if kind == .ghost {
            Capsule().strokeBorder(Color.borderGhost, lineWidth: 1)
        }
    }

    /// 2px ring, 2px outside the pill (negative padding grows the overlay).
    @ViewBuilder private var focusRing: some View {
        if appearance.showsFocusRing {
            Capsule().strokeBorder(Color.actionPrimary, lineWidth: 2).padding(-4)
        }
    }
}

/// A `ButtonStyle` restyles any `Button`, like a styled component wrapping
/// `<button>` in React: behavior (keyboard, accessibility) stays native.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ButtonShell(kind: .primary, isPressed: configuration.isPressed, label: configuration.label)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ButtonShell(kind: .ghost, isPressed: configuration.isPressed, label: configuration.label)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Usage: `Button("Start") { }.buttonStyle(.primary)`
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { GhostButtonStyle() }
}
