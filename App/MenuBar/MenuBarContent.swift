import KeyboardShortcuts
import SwiftUI
import TimeTrackerCore

struct MenuBarContent: View {
    let model: AppModel
    let onTogglePalette: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x3) {
            if let entry = model.running {
                RunningTimerView(model: model, entry: entry)
            } else {
                idle
            }
            if let message = model.errorMessage {
                ErrorStrip(message)
            }
            Divider()
            shortcutRow("Палитра", name: .togglePalette)
            shortcutRow("Журнал", name: .openJournal)
            HStack(spacing: Space.x2) {
                Button("Палитра") { onTogglePalette() }
                    .buttonStyle(.ghost).lineLimit(1).fixedSize()
                Button("Журнал") { AppRouter.shared.openJournal() }
                    .buttonStyle(.ghost).lineLimit(1).fixedSize()
                Spacer()
                Button("Выйти") { NSApp.terminate(nil) }
                    .buttonStyle(.ghost).lineLimit(1).fixedSize()
            }
        }
        .padding(Space.x4)
        .frame(width: 340)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.surfaceCanvas)
    }

    private var idle: some View {
        VStack(alignment: .leading, spacing: Space.x1) {
            Text(PopoverText.idleTitle)
                .typeRole(.bodyEmphasis)
                .foregroundStyle(Color.textPrimary)
            Text(PopoverText.idleHint(paletteShortcut: HotkeyService.shortcutDescription(for: .togglePalette)))
                .typeRole(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private func shortcutRow(_ title: String, name: KeyboardShortcuts.Name) -> some View {
        HStack {
            Text("\(title): \(HotkeyService.shortcutDescription(for: name) ?? "не задан")")
                .typeRole(.caption)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Button("Изменить…") { AppRouter.shared.openSettings() }
                .buttonStyle(.ghost).lineLimit(1).fixedSize()
        }
    }
}
