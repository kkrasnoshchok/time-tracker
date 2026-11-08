/// Pure rule for the input border, kept out of the view so it can be unit
/// tested (like extracting a pure function from a React component).
enum InputAppearance {
    static func borderToken(isFocused: Bool) -> ColorToken {
        isFocused ? .actionPrimary : .textTertiary
    }
}
