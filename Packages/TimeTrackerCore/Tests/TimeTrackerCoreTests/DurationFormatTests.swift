import Foundation
import Testing
@testable import TimeTrackerCore

struct DurationFormatTests {
    @Test(arguments: [
        (0.0, "0:00"),
        (42.0, "0:42"),
        (59.9, "0:59"),
        (125.0, "2:05"),
        (3599.0, "59:59"),
        (3600.0, "1:00:00"),
        (3725.0, "1:02:05"),
        (36_000.0, "10:00:00"),
        (360_000.0, "100:00:00"),
        (-5.0, "0:00")
    ])
    func clockFormat(seconds: Double, expected: String) {
        #expect(DurationFormat.clock(seconds) == expected)
    }

    @Test(arguments: [
        (0.0, "0 мин"),
        (59.0, "0 мин"),
        (60.0, "1 мин"),
        (2700.0, "45 мин"),
        (3600.0, "1 ч"),
        (3660.0, "1 ч 1 мин"),
        (5400.0, "1 ч 30 мин"),
        (90_000.0, "25 ч"),
        (-30.0, "0 мин")
    ])
    func shortFormat(seconds: Double, expected: String) {
        #expect(DurationFormat.short(seconds) == expected)
    }
}
