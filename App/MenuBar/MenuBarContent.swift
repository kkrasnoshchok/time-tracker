import SwiftUI
import TimeTrackerCore

struct MenuBarContent: View {
    let model: AppModel
    let onTogglePalette: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let entry = model.running {
                RunningTimerView(model: model, entry: entry)
            } else {
                Text("Таймер не запущен")
                    .font(.headline)
                Text("Начните запись хоткеем или кнопкой «Палитра».")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let message = model.errorMessage {
                Text(message).font(.caption).foregroundStyle(.red)
            }
            Divider()
            HStack {
                Text("Палитра: \(HotkeyService.currentShortcutDescription ?? "не задан")")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Изменить…") { AppRouter.shared.openSettings() }
            }
            HStack {
                Button("Палитра") { onTogglePalette() }
                Button("Журнал") { AppRouter.shared.openJournal() }
                Spacer()
                Button("Выйти") { NSApp.terminate(nil) }
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}
