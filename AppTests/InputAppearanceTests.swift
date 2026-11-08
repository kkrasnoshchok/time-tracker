import Testing
@testable import TimeTracker

struct InputAppearanceTests {
    @Test(arguments: [
        (false, ColorToken.textTertiary),
        (true, ColorToken.actionPrimary)
    ])
    func borderFollowsFocus(isFocused: Bool, expected: ColorToken) {
        #expect(InputAppearance.borderToken(isFocused: isFocused) == expected)
    }
}
