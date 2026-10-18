import SwiftUI
import TimeTrackerCore

/// Stand-in until the Journal arrives in a later task.
struct JournalPlaceholderView: View {
    let model: AppModel

    var body: some View {
        VStack(spacing: 8) {
            Text("Журнал").font(.title2)
            Text("Здесь будут записи по дням.")
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 480, minHeight: 320)
    }
}
