/// Pure state rules shared by the button styles, so they can be unit-tested
/// without rendering. Like a plain function `resolve(state) => style` in TS.
struct ButtonAppearance: Equatable, Sendable {
    let opacity: Double
    let showsFocusRing: Bool

    static func resolve(isEnabled: Bool, isPressed: Bool, isFocused: Bool) -> ButtonAppearance {
        // Disabled wins over pressed; focus shows only when enabled.
        guard isEnabled else { return ButtonAppearance(opacity: 0.4, showsFocusRing: false) }
        return ButtonAppearance(opacity: isPressed ? 0.8 : 1, showsFocusRing: isFocused)
    }
}
