import AppKit
import SwiftUI
import TimeTrackerCore

/// Owns the palette window and its view model; the hotkey and the menu bar both call `toggle()`.
@MainActor
final class PaletteController {
    private let viewModel: PaletteViewModel
    private var panel: PalettePanel?

    init(model: AppModel) {
        let viewModel = PaletteViewModel(store: model.store)
        self.viewModel = viewModel
        self.panel = PalettePanel(rootView: PaletteView(viewModel: viewModel, model: model) { [weak self] in
            self?.hide()
        })
    }

    func toggle() {
        if panel?.isVisible == true { hide() } else { show() }
    }

    func show() {
        viewModel.input = ""
        viewModel.reload()
        panel?.centerOnActiveScreen()
        panel?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }
}
