import SwiftUI
import Testing
@testable import TimeTracker

@MainActor
struct PalettePanelTests {
    @Test func resigningKeyNotifiesTheOwner() {
        let panel = PalettePanel(rootView: EmptyView())
        var closed = 0
        panel.onResignKey = { closed += 1 }

        panel.resignKey()

        #expect(closed == 1)
    }

    @Test func panelShowsAndHidesWithoutAnimation() {
        let panel = PalettePanel(rootView: EmptyView())

        #expect(panel.animationBehavior == .none)
    }

    @Test func resigningKeyWithoutAnOwnerDoesNothing() {
        let panel = PalettePanel(rootView: EmptyView())

        panel.resignKey()

        #expect(panel.onResignKey == nil)
    }
}
