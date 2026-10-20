import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Горячая клавиша") {
                KeyboardShortcuts.Recorder("Открыть палитру:", name: .togglePalette)
                Button("Сбросить на ⌃⌥T") { KeyboardShortcuts.reset(.togglePalette) }
                Text("Нажмите в поле и введите новое сочетание. Крестик в поле убирает хоткей.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .padding()
    }
}
