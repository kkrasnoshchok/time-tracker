import KeyboardShortcuts
import SwiftUI
import TimeTrackerCore

struct SettingsView: View {
    @State private var hotkeys = HotkeySettingsViewModel(
        palette: KeyboardShortcuts.getShortcut(for: .togglePalette)?.keyCombo,
        journal: KeyboardShortcuts.getShortcut(for: .openJournal)?.keyCombo
    )

    var body: some View {
        Form {
            Section("Горячие клавиши") {
                recorder("Открыть палитру:", name: .togglePalette, action: .palette, resetTitle: "Сбросить на ⌃⌥T")
                recorder("Открыть журнал:", name: .openJournal, action: .journal, resetTitle: "Сбросить на ⌃⌥J")
                Text("Нажмите в поле и введите новое сочетание. Крестик в поле убирает хоткей.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .padding()
    }

    @ViewBuilder
    private func recorder(
        _ title: String, name: KeyboardShortcuts.Name, action: HotkeyAction, resetTitle: String
    ) -> some View {
        KeyboardShortcuts.Recorder(title, name: name) { apply($0, to: action, name: name) }
        if let error = hotkeys.error(for: action) {
            Text(error).font(.callout).foregroundStyle(.red)
        }
        Button(resetTitle) {
            KeyboardShortcuts.reset(name)
            apply(KeyboardShortcuts.getShortcut(for: name), to: action, name: name)
        }
    }

    /// The library saves the shortcut before calling us, so on rejection we put the old one back.
    private func apply(_ shortcut: KeyboardShortcuts.Shortcut?, to action: HotkeyAction, name: KeyboardShortcuts.Name) {
        let previous = hotkeys.shortcut(for: action)
        if !hotkeys.assign(shortcut?.keyCombo, to: action) {
            KeyboardShortcuts.setShortcut(previous.map(KeyboardShortcuts.Shortcut.init), for: name)
        }
    }
}
