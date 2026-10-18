import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Default ⌃⌥T; the user can change it in Settings.
    @MainActor static let togglePalette = Self("togglePalette", default: .init(.t, modifiers: [.control, .option]))
}

/// Listens for the global hotkey and calls `onToggle` on the main actor.
@MainActor
final class HotkeyService {
    init(onToggle: @escaping @MainActor () -> Void) {
        KeyboardShortcuts.onKeyDown(for: .togglePalette) {
            MainActor.assumeIsolated { onToggle() }
        }
    }

    static var currentShortcutDescription: String? {
        KeyboardShortcuts.getShortcut(for: .togglePalette)?.description
    }
}
