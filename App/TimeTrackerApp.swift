import SwiftUI
import TimeTrackerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The app lives in the menu bar; closing the Journal window must not quit it.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
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
            if let title = model.menuBarTitle {
                Text(title).monospacedDigit()
            } else {
                Image(systemName: "clock")
            }
        }
        .menuBarExtraStyle(.window)

        Window("Журнал", id: "journal") {
            JournalPlaceholderView(model: model)
        }
    }
}
