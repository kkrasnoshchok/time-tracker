import Foundation
import Testing
@testable import TimeTrackerCore

@MainActor
struct DayGroupingTests {
    private let time = TestTimeProvider(at(0).addingTimeInterval(60 * 86_400))
    private let store: TimeStore
    private let work: EntryCategory

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    init() throws {
        store = try TimeStore.inMemory(time: time)
        work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
    }

    @discardableResult
    private func add(_ start: Date, _ end: Date, title: String? = nil) throws -> TimeEntry {
        try store.addEntry(
            span: TimeSpan(start: start, end: end), category: work, title: title, tags: [], notes: nil,
            allowOverlap: true
        )
    }

    private func day(_ offset: Int) -> Date {
        at(0).addingTimeInterval(TimeInterval(offset) * 86_400)
    }

    @Test func emptyInputGivesNoGroups() {
        #expect(DayGrouping.group([], calendar: utc, now: at(12)).isEmpty)
    }

    @Test func groupsByStartDayNewestFirstWithNewestEntriesFirst() throws {
        let monday = try add(day(0).addingTimeInterval(9 * 3600), day(0).addingTimeInterval(10 * 3600))
        let tuesdayEarly = try add(day(1).addingTimeInterval(8 * 3600), day(1).addingTimeInterval(9 * 3600))
        let tuesdayLate = try add(day(1).addingTimeInterval(14 * 3600), day(1).addingTimeInterval(16 * 3600))
        let groups = DayGrouping.group([monday, tuesdayLate, tuesdayEarly], calendar: utc, now: day(5))
        #expect(groups.map(\.day) == [day(1), day(0)])
        #expect(groups[0].entries == [tuesdayLate, tuesdayEarly])
        #expect(groups[0].total == 3 * 3600)
        #expect(groups[1].entries == [monday])
        #expect(groups[1].total == 3600)
    }

    @Test func entryStartingExactlyAtMidnightBelongsToThatDay() throws {
        let entry = try add(day(1), day(1).addingTimeInterval(3600))
        let groups = DayGrouping.group([entry], calendar: utc, now: day(5))
        #expect(groups.count == 1)
        #expect(groups[0].day == day(1))
        #expect(groups[0].total == 3600)
    }

    @Test func entryCrossingMidnightSplitsTotalsBetweenDays() throws {
        let entry = try add(day(0).addingTimeInterval(23 * 3600), day(1).addingTimeInterval(3600))
        let groups = DayGrouping.group([entry], calendar: utc, now: day(5))
        #expect(groups.map(\.day) == [day(1), day(0)])
        #expect(groups[0].entries.isEmpty && groups[0].total == 3600)
        #expect(groups[1].entries == [entry] && groups[1].total == 3600)
    }

    @Test func entrySpanningSeveralDaysFillsEveryDay() throws {
        let entry = try add(day(0).addingTimeInterval(22 * 3600), day(2).addingTimeInterval(2 * 3600))
        let groups = DayGrouping.group([entry], calendar: utc, now: day(5))
        let expectedTotals: [TimeInterval] = [7_200, 86_400, 7_200]
        #expect(groups.map(\.total) == expectedTotals)
        #expect(groups.map(\.day) == [day(2), day(1), day(0)])
    }

    @Test func dstSpringForwardDayKeepsRealDuration() throws {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        func local(_ month: Int, _ dayOfMonth: Int, _ hour: Int, _ minute: Int) -> Date {
            newYork.date(from: DateComponents(
                year: 2026, month: month, day: dayOfMonth, hour: hour, minute: minute
            ))!
        }
        // 2026-03-08: clocks jump 02:00 -> 03:00, so 00:00-23:59 is 22h59m of real time.
        let entry = try add(local(3, 8, 0, 0), local(3, 8, 23, 59))
        let groups = DayGrouping.group([entry], calendar: newYork, now: local(4, 1, 0, 0))
        #expect(groups.count == 1)
        #expect(groups[0].total == 22 * 3600 + 59 * 60)
        #expect(groups[0].total == entry.end!.timeIntervalSince(entry.start))
    }

    @Test func midnightAfterSpringForwardDayIsCalendarMidnight() throws {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        let start = newYork.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 22))!
        let end = newYork.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 2))!
        let midnight = newYork.date(from: DateComponents(year: 2026, month: 3, day: 9))!
        let entry = try add(start, end)
        let groups = DayGrouping.group([entry], calendar: newYork, now: end.addingTimeInterval(86_400))
        let expectedTotals: [TimeInterval] = [7_200, 7_200]
        #expect(groups.map(\.day) == [midnight, newYork.startOfDay(for: start)])
        #expect(groups.map(\.total) == expectedTotals)
    }

    @Test func dstFallBackNightCountsTheRepeatedHour() throws {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        let start = newYork.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 0, minute: 30))!
        let end = start.addingTimeInterval(3 * 3600) // crosses the repeated 01:00-02:00 hour
        let entry = try add(start, end)
        let groups = DayGrouping.group([entry], calendar: newYork, now: end.addingTimeInterval(86_400))
        #expect(groups.count == 1)
        #expect(groups[0].total == 3 * 3600)
    }

    @Test func runningEntryUsesNowForTotal() throws {
        time.current = day(3).addingTimeInterval(9 * 3600)
        let running = try store.startTimer(category: work, title: nil, tags: [])
        let now = day(3).addingTimeInterval(10.5 * 3600)
        let groups = DayGrouping.group([running], calendar: utc, now: now)
        #expect(groups.count == 1)
        #expect(groups[0].total == 5400)
    }

    @Test func totalOfDayWithRunningEntryGrowsWithNow() throws {
        time.current = day(3).addingTimeInterval(9 * 3600)
        let running = try store.startTimer(category: work, title: nil, tags: [])
        let reloadedAt = day(3).addingTimeInterval(10 * 3600)
        let groups = DayGrouping.group([running], calendar: utc, now: reloadedAt)
        #expect(groups[0].total == 3600)
        #expect(groups[0].liveTotal(at: reloadedAt) == 3600)
        #expect(groups[0].liveTotal(at: reloadedAt.addingTimeInterval(90)) == 3690)
    }

    @Test func totalNeverShrinksWhenNowIsEarlierThanGrouping() throws {
        time.current = day(3).addingTimeInterval(9 * 3600)
        let running = try store.startTimer(category: work, title: nil, tags: [])
        let reloadedAt = day(3).addingTimeInterval(10 * 3600)
        let groups = DayGrouping.group([running], calendar: utc, now: reloadedAt)
        #expect(groups[0].liveTotal(at: reloadedAt.addingTimeInterval(-60)) == 3600)
    }

    @Test func totalOfDayWithoutRunningEntryIgnoresNow() throws {
        let entry = try add(day(3).addingTimeInterval(9 * 3600), day(3).addingTimeInterval(10 * 3600))
        let reloadedAt = day(3).addingTimeInterval(12 * 3600)
        let groups = DayGrouping.group([entry], calendar: utc, now: reloadedAt)
        #expect(groups[0].liveTotal(at: reloadedAt.addingTimeInterval(600)) == 3600)
    }

    @Test func pastDayStaysFixedWhileRunningEntryGrowsToday() throws {
        let yesterday = try add(day(2).addingTimeInterval(9 * 3600), day(2).addingTimeInterval(10 * 3600))
        time.current = day(3).addingTimeInterval(9 * 3600)
        let running = try store.startTimer(category: work, title: nil, tags: [])
        let reloadedAt = day(3).addingTimeInterval(10 * 3600)
        let groups = DayGrouping.group([yesterday, running], calendar: utc, now: reloadedAt)
        let later = reloadedAt.addingTimeInterval(300)
        #expect(groups[0].liveTotal(at: later) == 3900)
        #expect(groups[1].liveTotal(at: later) == 3600)
    }

    @Test func overnightRunningEntryMakesOnlyTodayLive() throws {
        time.current = day(2).addingTimeInterval(23 * 3600)
        let running = try store.startTimer(category: work, title: nil, tags: [])
        let reloadedAt = day(3).addingTimeInterval(3600)
        let groups = DayGrouping.group([running], calendar: utc, now: reloadedAt)
        let later = reloadedAt.addingTimeInterval(300)
        #expect(groups.map(\.day) == [day(3), day(2)])
        #expect(groups.map(\.isLive) == [true, false])
        #expect(groups[0].liveTotal(at: later) == 3600 + 300)
        #expect(groups[1].liveTotal(at: later) == 3600)
    }

    @Test func runningEntryStartingAfterNowDoesNotMakeGroupLive() throws {
        time.current = day(3).addingTimeInterval(11 * 3600)
        let running = try store.startTimer(category: work, title: nil, tags: [])
        let reloadedAt = day(3).addingTimeInterval(10 * 3600)
        let groups = DayGrouping.group([running], calendar: utc, now: reloadedAt)
        #expect(groups[0].isLive == false)
        #expect(groups[0].liveTotal(at: reloadedAt.addingTimeInterval(600)) == groups[0].total)
    }

    @Test func zeroLengthEntryStillAppears() throws {
        let entry = try add(day(1).addingTimeInterval(3600), day(1).addingTimeInterval(3600))
        let groups = DayGrouping.group([entry], calendar: utc, now: day(5))
        #expect(groups.count == 1 && groups[0].total == 0 && groups[0].entries == [entry])
    }
}
