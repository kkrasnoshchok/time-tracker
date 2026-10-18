import Foundation

/// Wires the global hotkey to the palette window for the lifetime of the app.
@MainActor
final class AppCoordinator {
    let palette: PaletteController
    private var hotkey: HotkeyService?

    init(model: AppModel) {
        palette = PaletteController(model: model)
        hotkey = HotkeyService { [palette] in palette.toggle() }
    }
}
