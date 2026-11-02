import Testing
@testable import TimeTracker

struct ButtonAppearanceTests {
    @Test(arguments: [
        // (isEnabled, isPressed, isFocused, opacity, showsFocusRing)
        (true, false, false, 1.0, false),
        (true, true, false, 0.8, false),
        (false, false, false, 0.4, false),
        (false, true, false, 0.4, false),
        (true, false, true, 1.0, true),
        (true, true, true, 0.8, true),
        (false, false, true, 0.4, false),
        (false, true, true, 0.4, false)
    ])
    func resolvesStateRules(isEnabled: Bool, isPressed: Bool, isFocused: Bool, opacity: Double, ring: Bool) {
        let appearance = ButtonAppearance.resolve(isEnabled: isEnabled, isPressed: isPressed, isFocused: isFocused)
        #expect(appearance.opacity == opacity)
        #expect(appearance.showsFocusRing == ring)
    }
}
