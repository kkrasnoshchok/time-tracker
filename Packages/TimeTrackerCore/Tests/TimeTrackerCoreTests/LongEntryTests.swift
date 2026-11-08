import Foundation
import Testing
@testable import TimeTrackerCore

struct LongEntryTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func at(hours: Int, minutes: Int = 0) -> Date {
        start.addingTimeInterval(TimeInterval(hours * 3600 + minutes * 60))
    }

    @Test func finishedJustUnderEightHoursIsNotLong() {
        #expect(!LongEntry.isLong(start: start, end: at(hours: 7, minutes: 59), now: at(hours: 20)))
    }

    @Test func finishedExactlyEightHoursIsLong() {
        #expect(LongEntry.isLong(start: start, end: at(hours: 8), now: at(hours: 20)))
    }

    @Test func runningUsesNowMinusStart() {
        #expect(!LongEntry.isLong(start: start, end: nil, now: at(hours: 7, minutes: 59)))
        #expect(LongEntry.isLong(start: start, end: nil, now: at(hours: 8)))
    }

    @Test func finishedIgnoresNow() {
        #expect(!LongEntry.isLong(start: start, end: at(hours: 1), now: at(hours: 30)))
    }

    @Test func spanningMidnightUsesFullDuration() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let evening = calendar.date(from: DateComponents(year: 2026, month: 11, day: 3, hour: 22))!
        let morning = calendar.date(from: DateComponents(year: 2026, month: 11, day: 4, hour: 7))!
        #expect(LongEntry.isLong(start: evening, end: morning, now: morning))
    }

    @Test func finishedWithEndBeforeStartIsNotLong() {
        #expect(!LongEntry.isLong(start: start, end: start.addingTimeInterval(-3600), now: at(hours: 20)))
    }

    @Test func finishedWithZeroDurationIsNotLong() {
        #expect(!LongEntry.isLong(start: start, end: start, now: at(hours: 20)))
    }

    @Test func clockBeforeStartIsNotLong() {
        #expect(!LongEntry.isLong(start: start, end: nil, now: start.addingTimeInterval(-3600)))
    }
}
