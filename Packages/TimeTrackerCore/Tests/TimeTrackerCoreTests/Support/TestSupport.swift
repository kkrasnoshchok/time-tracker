import Foundation
import Synchronization
@testable import TimeTrackerCore

/// Fixed reference day (2027-01-15 00:00 UTC) so tests never depend on the real clock.
let referenceMidnight = Date(timeIntervalSince1970: TimeInterval(1_800_000_000 - 1_800_000_000 % 86_400))

/// A moment on the reference day, in UTC.
func at(_ hour: Int, _ minute: Int = 0) -> Date {
    referenceMidnight.addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))
}

/// A `TimeProvider` whose "now" the test controls.
final class TestTimeProvider: TimeProvider {
    private let storage: Mutex<Date>

    init(_ start: Date) {
        storage = Mutex(start)
    }

    var current: Date {
        get { storage.withLock { $0 } }
        set { storage.withLock { $0 = newValue } }
    }

    func now() -> Date { current }
}
