import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Хоткей палитры:", name: .togglePalette)
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
    }
}
