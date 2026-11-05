import Foundation
import Observation
import TimeTrackerCore

/// App-wide observable state: the running timer and a once-a-second clock for the menu bar.
@MainActor
@Observable
final class AppModel {
    let store: TimeStore
    private(set) var running: TimeEntry?
    private(set) var now: Date
    private(set) var errorMessage: String?

    init(store: TimeStore) {
        self.store = store
        self.now = store.time.now()
        refresh()
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.refresh()
            }
        }
    }

    /// Call after anything changed the store (palette, journal edits).
    func refresh() {
        running = store.runningEntry()
        now = store.time.now()
    }

    var elapsed: TimeInterval {
        guard let running else { return 0 }
        return max(0, now.timeIntervalSince(running.start))
    }

    var menuBarTitle: String? {
        guard let running else { return nil }
        return MenuBarLabel.text(category: running.category?.name, elapsed: elapsed)
    }

    var menuBarAccessibilityLabel: String {
        MenuBarLabel.accessibilityLabel(
            category: running?.category?.name, elapsed: running == nil ? nil : elapsed)
    }

    func stopTimer() {
        perform { try store.stopTimer() }
    }

    func setNotes(_ notes: String, for entry: TimeEntry) {
        perform { try store.setNotes(notes, for: entry) }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
        refresh()
    }
}
