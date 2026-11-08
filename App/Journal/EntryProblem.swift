import TimeTrackerCore

/// What the error strip shows for a failed save. Pure, so tests can pin it.
enum EntryProblem {
    static func message(_ error: StoreError) -> String { error.message }

    /// Only an overlap can be forced through; every other error has no way out but fixing the form.
    static func actionLabel(_ error: StoreError) -> String? {
        if case .overlap = error { return "Всё равно" }
        return nil
    }
}
