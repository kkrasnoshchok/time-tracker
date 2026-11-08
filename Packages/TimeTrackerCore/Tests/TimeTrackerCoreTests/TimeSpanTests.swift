import Foundation
import Testing
@testable import TimeTrackerCore

struct TimeSpanTests {
    private func span(_ start: Date, _ end: Date?) throws -> TimeSpan {
        try TimeSpan(start: start, end: end)
    }

    @Test func endBeforeStartThrows() {
        #expect(throws: TimeSpanError.endBeforeStart) {
            try TimeSpan(start: at(11), end: at(10))
        }
    }

    @Test func zeroLengthSpanIsValid() throws {
        let zero = try span(at(10), at(10))
        #expect(zero.duration(now: at(12)) == 0)
    }

    @Test func touchingSpansDoNotOverlap() throws {
        let first = try span(at(10), at(11))
        let second = try span(at(11), at(12))
        #expect(first.overlaps(second, now: at(13)) == false)
        #expect(second.overlaps(first, now: at(13)) == false)
    }

    @Test func partialOverlap() throws {
        let first = try span(at(10), at(11, 30))
        let second = try span(at(11), at(12))
        #expect(first.overlaps(second, now: at(13)))
        #expect(second.overlaps(first, now: at(13)))
    }

    @Test func containedSpanOverlaps() throws {
        let outer = try span(at(9), at(17))
        let inner = try span(at(12), at(13))
        #expect(outer.overlaps(inner, now: at(18)))
        #expect(inner.overlaps(outer, now: at(18)))
    }

    @Test func openSpanTreatsNowAsEnd() throws {
        let running = try span(at(10), nil)
        let inside = try span(at(10, 15), at(10, 20))
        let later = try span(at(11), at(12))
        #expect(running.overlaps(inside, now: at(10, 30)))
        #expect(running.overlaps(later, now: at(10, 30)) == false)
    }

    @Test func durationOfClosedSpan() throws {
        #expect(try span(at(10), at(11, 30)).duration(now: at(23)) == 5400)
    }

    @Test func durationOfOpenSpanUsesNow() throws {
        #expect(try span(at(10), nil).duration(now: at(10, 45)) == 2700)
    }

    @Test func durationOfOpenSpanNeverGoesNegativeWhenNowIsBeforeStart() throws {
        #expect(try span(at(10), nil).duration(now: at(9, 50)) == 0)
    }

    @Test func systemTimeProviderReturnsCurrentTime() {
        let before = Date()
        let value = SystemTimeProvider().now()
        #expect(value >= before && value <= Date())
    }
}
