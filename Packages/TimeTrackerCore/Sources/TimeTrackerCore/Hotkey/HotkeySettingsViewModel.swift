import Observation

/// A keyboard shortcut as plain numbers, so Core does not depend on the KeyboardShortcuts library.
/// (Like a TS type `{ keyCode: number; modifiers: number }`.)
public struct KeyCombo: Equatable, Sendable {
    public let keyCode: Int
    public let modifiers: Int

    public init(keyCode: Int, modifiers: Int) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

/// The in-app global hotkeys.
public enum HotkeyAction: CaseIterable, Sendable {
    case palette
    case journal
}

/// Rules for assigning hotkeys: one shortcut cannot serve two actions.
/// The Settings screen renders `error(for:)` next to each recorder.
@MainActor
@Observable
public final class HotkeySettingsViewModel {
    private var shortcuts: [HotkeyAction: KeyCombo]
    private var errors: [HotkeyAction: String] = [:]

    public init(palette: KeyCombo?, journal: KeyCombo?) {
        shortcuts = [.palette: palette, .journal: journal].compactMapValues { $0 }
    }

    public func shortcut(for action: HotkeyAction) -> KeyCombo? { shortcuts[action] }

    public func error(for action: HotkeyAction) -> String? { errors[action] }

    /// Returns `true` if accepted. On `false` the stored value is unchanged
    /// and the caller must put the previous shortcut back in the UI.
    @discardableResult
    public func assign(_ combo: KeyCombo?, to action: HotkeyAction) -> Bool {
        errors[action] = nil
        if let combo, let other = HotkeyAction.allCases.first(where: { $0 != action && shortcuts[$0] == combo }) {
            errors[action] = "Это сочетание уже занято: \(Self.name(of: other))."
            return false
        }
        shortcuts[action] = combo
        return true
    }

    private static func name(of action: HotkeyAction) -> String {
        switch action {
        case .palette: "палитра"
        case .journal: "журнал"
        }
    }
}
