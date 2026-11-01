import Testing
@testable import TimeTrackerCore

@MainActor
struct HotkeySettingsViewModelTests {
    private let controT = KeyCombo(keyCode: 17, modifiers: 4096 + 2048)
    private let controlK = KeyCombo(keyCode: 40, modifiers: 4096 + 2048)

    private func makeViewModel() -> HotkeySettingsViewModel {
        HotkeySettingsViewModel(palette: controT, journal: KeyCombo(keyCode: 38, modifiers: 4096 + 2048))
    }

    @Test func freeShortcutIsAccepted() {
        let viewModel = makeViewModel()
        #expect(viewModel.assign(controlK, to: .journal))
        #expect(viewModel.shortcut(for: .journal) == controlK)
        #expect(viewModel.error(for: .journal) == nil)
    }

    @Test func journalRejectsPaletteShortcut() {
        let viewModel = makeViewModel()
        let before = viewModel.shortcut(for: .journal)
        #expect(!viewModel.assign(controT, to: .journal))
        #expect(viewModel.shortcut(for: .journal) == before)
        #expect(viewModel.error(for: .journal) != nil)
        #expect(viewModel.error(for: .palette) == nil)
    }

    @Test func paletteRejectsJournalShortcut() {
        let viewModel = makeViewModel()
        let journal = viewModel.shortcut(for: .journal)
        let before = viewModel.shortcut(for: .palette)
        #expect(journal != nil)
        #expect(!viewModel.assign(journal, to: .palette))
        #expect(viewModel.shortcut(for: .palette) == before)
        #expect(viewModel.error(for: .palette) != nil)
        #expect(viewModel.error(for: .journal) == nil)
    }

    @Test func clearingIsAcceptedAndClearsError() {
        let viewModel = makeViewModel()
        _ = viewModel.assign(controT, to: .journal)
        #expect(viewModel.error(for: .journal) != nil)
        #expect(viewModel.assign(nil, to: .journal))
        #expect(viewModel.shortcut(for: .journal) == nil)
        #expect(viewModel.error(for: .journal) == nil)
    }

    @Test func retryAfterErrorClearsIt() {
        let viewModel = makeViewModel()
        _ = viewModel.assign(controT, to: .journal)
        #expect(viewModel.assign(controlK, to: .journal))
        #expect(viewModel.error(for: .journal) == nil)
    }

    @Test func reassigningSameShortcutToSameActionIsAccepted() {
        let viewModel = makeViewModel()
        #expect(viewModel.assign(controT, to: .palette))
        #expect(viewModel.error(for: .palette) == nil)
    }
}
