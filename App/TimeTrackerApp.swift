import SwiftUI
import TimeTrackerCore

@main
struct TimeTrackerApp: App {
    var body: some Scene {
        WindowGroup("Журнал") {
            Text("Time Tracker \(TimeTrackerCore.version)")
                .frame(minWidth: 320, minHeight: 200)
        }
    }
}
