import KeyboardShortcuts
import TimeTrackerCore

extension KeyboardShortcuts.Name {
    /// Default ⌃⌥T; the user can change it in Settings.
    @MainActor static let togglePalette = Self("togglePalette", default: .init(.t, modifiers: [.control, .option]))
    /// Default ⌃⌥J; the user can change it in Settings.
    @MainActor static let openJournal = Self("openJournal", default: .init(.j, modifiers: [.control, .option]))
}

extension KeyboardShortcuts.Shortcut {
    /// Library shortcut -> plain numbers that Core understands (like mapping an API object to a DTO).
    var keyCombo: KeyCombo { KeyCombo(keyCode: carbonKeyCode, modifiers: carbonModifiers) }

    init(_ combo: KeyCombo) { self.init(carbonKeyCode: combo.keyCode, carbonModifiers: combo.modifiers) }
}

/// Listens for the global hotkeys and calls the matching callback on the main actor.
@MainActor
final class HotkeyService {
    init(onTogglePalette: @escaping @MainActor () -> Void, onOpenJournal: @escaping @MainActor () -> Void) {
        KeyboardShortcuts.onKeyDown(for: .togglePalette) {
            MainActor.assumeIsolated { onTogglePalette() }
        }
        KeyboardShortcuts.onKeyDown(for: .openJournal) {
            MainActor.assumeIsolated { onOpenJournal() }
        }
    }

    static func shortcutDescription(for name: KeyboardShortcuts.Name) -> String? {
        KeyboardShortcuts.getShortcut(for: name)?.description
    }
}
