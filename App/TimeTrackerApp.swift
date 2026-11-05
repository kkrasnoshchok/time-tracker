import SwiftUI
import TimeTrackerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The app lives in the menu bar; closing the Journal window must not quit it.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    /// Clicking the Dock icon while no window is open should show the Journal.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { AppRouter.shared.openJournal() }
        return true
    }
}

@main
struct TimeTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model: AppModel
    @State private var coordinator: AppCoordinator

    init() {
        let model = AppModel(store: AppEnvironment.makeStore())
        _model = State(initialValue: model)
        _coordinator = State(initialValue: AppCoordinator(model: model))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(model: model, onTogglePalette: coordinator.palette.toggle)
        } label: {
            Group {
                if let title = model.menuBarTitle {
                    Text(title).monospacedDigit()
                } else {
                    Image(systemName: "clock")
                }
            }
            .accessibilityLabel(model.menuBarAccessibilityLabel)
            .background(RouterCapture())
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }

        Window("Журнал", id: "journal") {
            JournalRootView(model: model)
        }
    }
}
