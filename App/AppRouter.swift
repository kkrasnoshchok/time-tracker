import AppKit
import SwiftUI

/// Opens the app's windows from anywhere (popover buttons, Dock click) and brings them to the front.
///
/// SwiftUI only hands out `openWindow`/`openSettings` inside views, so `RouterCapture` stores them
/// here once the menu bar label appears.
@MainActor
final class AppRouter {
    static let shared = AppRouter()

    private var openWindowAction: OpenWindowAction?
    private var openSettingsAction: OpenSettingsAction?

    func capture(openWindow: OpenWindowAction, openSettings: OpenSettingsAction) {
        openWindowAction = openWindow
        openSettingsAction = openSettings
    }

    func openJournal() {
        // A minimized window is not brought back by `openWindow`, so restore it first.
        // The title is the one declared in `Window("Журнал", id: "journal")`.
        NSApp.windows.first { $0.title == "Журнал" && $0.isMiniaturized }?.deminiaturize(nil)
        openWindowAction?(id: "journal")
        bringToFront()
    }

    func openSettings() {
        openSettingsAction?()
        bringToFront()
    }

    /// A menu bar app is rarely the active app. The cooperative `NSApp.activate()` is then ignored
    /// and the window opens behind other apps without focus, so we force activation.
    private func bringToFront() {
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// Invisible view that hands the scene-level window actions to `AppRouter`.
struct RouterCapture: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onAppear { AppRouter.shared.capture(openWindow: openWindow, openSettings: openSettings) }
    }
}
