import Foundation

/// Pure strings for the popover, kept out of the views so they can be tested.
enum PopoverText {
    static let idleTitle = "Таймер не запущен"
    static let noCategory = "Без категории"

    static func idleHint(paletteShortcut: String?) -> String {
        guard let paletteShortcut, !paletteShortcut.isEmpty else {
            return "Хоткей палитры не задан. Задайте его в настройках."
        }
        return "Начните запись: \(paletteShortcut)"
    }

    static func categoryName(_ name: String?) -> String {
        guard let name, !name.isEmpty else { return noCategory }
        return name
    }
}
