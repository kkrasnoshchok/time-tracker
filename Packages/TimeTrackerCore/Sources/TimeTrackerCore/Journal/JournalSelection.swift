import Foundation

/// Arrow-key movement through the Journal's entries (days already flattened,
/// in on-screen order). A pure function: the view only calls it, like a reducer.
public enum JournalSelection {
    /// The id to select after pressing an arrow key. `step` is +1 (down) or -1 (up).
    /// Nothing selected, or a selection that is no longer in the list, starts at
    /// the first row going down and the last row going up. Clamps at both ends.
    public static func next(from current: UUID?, in ids: [UUID], step: Int) -> UUID? {
        guard !ids.isEmpty else { return nil }
        guard let current, let index = ids.firstIndex(of: current) else {
            return step > 0 ? ids.first : ids.last
        }
        return ids[min(max(index + step, 0), ids.count - 1)]
    }
}
