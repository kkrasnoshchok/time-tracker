import KeyboardShortcuts
import SwiftUI
import TimeTrackerCore

/// The `Settings` scene is the app's preferences window (⌘,), like a `/settings` route.
/// The page is a card of hotkey rows on the canvas. The recorder itself is a system control and
/// keeps its look on purpose; only its label, hint and error line use the design tokens.
struct SettingsView: View {
    @State private var hotkeys = HotkeySettingsViewModel(
        palette: KeyboardShortcuts.getShortcut(for: .togglePalette)?.keyCombo,
        journal: KeyboardShortcuts.getShortcut(for: .openJournal)?.keyCombo
    )

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x4) {
            Text("Горячие клавиши")
                .typeRole(.title)
                .foregroundStyle(Color.textPrimary)
            VStack(alignment: .leading, spacing: Space.x4) {
                recorder("Открыть палитру", name: .togglePalette, action: .palette, resetTitle: "Сбросить на ⌃⌥T")
                recorder("Открыть журнал", name: .openJournal, action: .journal, resetTitle: "Сбросить на ⌃⌥J")
                Text("Нажмите в поле и введите новое сочетание. Крестик в поле убирает хоткей.")
                    .typeRole(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
        .padding(Space.x5)
        .frame(width: 440)
        .background(Color.surfaceCanvas)
    }

    /// `LabeledContent` is a label on the left and a control on the right in one row,
    /// like `<label>` + `<input>` in a flex row. The label is ours (token font); the recorder is the system one.
    private func recorder(
        _ title: String, name: KeyboardShortcuts.Name, action: HotkeyAction, resetTitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Space.x2) {
            LabeledContent {
                KeyboardShortcuts.Recorder(for: name) { apply($0, to: action, name: name) }
            } label: {
                Text(title).typeRole(.body).foregroundStyle(Color.textPrimary)
            }
            if let error = hotkeys.error(for: action) {
                ErrorStrip(error)
            }
            Button(resetTitle) {
                KeyboardShortcuts.reset(name)
                apply(KeyboardShortcuts.getShortcut(for: name), to: action, name: name)
            }
            .buttonStyle(.ghost)
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
