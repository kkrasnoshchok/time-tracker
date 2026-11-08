import TimeTrackerCore

/// Which suggestion row is highlighted by ↑/↓. A plain value type, like a `useReducer` state:
/// `nil` means "no row selected", so Enter keeps its old meaning.
struct PaletteSelection: Equatable {
    private(set) var index: Int?

    /// ↓: from none selects the first row; stops at the last row.
    mutating func moveDown(count: Int) {
        guard count > 0 else { index = nil; return }
        index = min((index ?? -1) + 1, count - 1)
    }

    /// ↑: from the first row clears the selection; from none stays none.
    mutating func moveUp(count: Int) {
        guard let current = index, count > 0, current > 0 else { index = nil; return }
        index = min(current, count) - 1
    }

    /// Text a highlighted suggestion puts in the field (Enter, Tab); `nil` for no highlight or any other row.
    func fillText(in items: [PaletteItem]) -> String? {
        guard let index, items.indices.contains(index), case .suggestion(let text) = items[index] else { return nil }
        return text
    }

    mutating func reset() {
        index = nil
    }
}
