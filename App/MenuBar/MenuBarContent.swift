import KeyboardShortcuts
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
            shortcutRow("Палитра", name: .togglePalette)
            shortcutRow("Журнал", name: .openJournal)
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

    private func shortcutRow(_ title: String, name: KeyboardShortcuts.Name) -> some View {
        HStack {
            Text("\(title): \(HotkeyService.shortcutDescription(for: name) ?? "не задан")")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Изменить…") { AppRouter.shared.openSettings() }
        }
    }
}
