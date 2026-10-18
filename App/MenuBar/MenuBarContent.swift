import SwiftUI
import TimeTrackerCore

struct MenuBarContent: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let entry = model.running {
                RunningTimerView(model: model, entry: entry)
            } else {
                Text("Таймер не запущен")
                    .font(.headline)
                Text("Начните запись горячей клавишей.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let message = model.errorMessage {
                Text(message).font(.caption).foregroundStyle(.red)
            }
            Divider()
            HStack {
                Button("Открыть журнал") {
                    openWindow(id: "journal")
                    NSApp.activate()
                }
                Spacer()
                Button("Выйти") { NSApp.terminate(nil) }
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}
