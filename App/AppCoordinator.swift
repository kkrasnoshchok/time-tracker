import Foundation

/// Wires the global hotkeys to the palette and Journal windows for the lifetime of the app.
@MainActor
final class AppCoordinator {
    let palette: PaletteController
    private var hotkey: HotkeyService?

    init(model: AppModel) {
        palette = PaletteController(model: model)
        hotkey = HotkeyService(
            onTogglePalette: { [palette] in palette.toggle() },
            onOpenJournal: { AppRouter.shared.openJournal() }
        )
    }
}
