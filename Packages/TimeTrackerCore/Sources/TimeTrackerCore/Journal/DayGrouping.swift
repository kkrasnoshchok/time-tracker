import Foundation

public struct DayGroup: Equatable {
    /// Start of the day in the calendar used for grouping.
    public let day: Date
    /// Entries that *started* on this day, newest first.
    public let entries: [TimeEntry]
    /// Time that falls inside this day, including the part of entries that started earlier.
    public let total: TimeInterval
    /// The `now` this group was computed at.
    public let asOf: Date
    /// True for the group of today when a running entry is among the input: its total keeps growing.
    public let isLive: Bool

    /// The day's total at `now`. Only a live group grows after grouping; never shrinks if `now` is earlier.
    public func liveTotal(at now: Date) -> TimeInterval {
        isLive ? total + max(0, now.timeIntervalSince(asOf)) : total
    }
}

public enum DayGrouping {
    /// Groups entries by day, newest day first. An entry is listed under the day it started,
    /// but its duration is split across every day it covers. Running entries last until `now`.
    public static func group(_ entries: [TimeEntry], calendar: Calendar, now: Date) -> [DayGroup] {
        var totals: [Date: TimeInterval] = [:]
        var listed: [Date: [TimeEntry]] = [:]
        let today = calendar.startOfDay(for: now)
        let hasRunning = entries.contains { $0.end == nil && $0.start <= now }

        for entry in entries {
            let start = entry.start
            let end = max(entry.end ?? now, start)
            let firstDay = calendar.startOfDay(for: start)
            listed[firstDay, default: []].append(entry)
            totals[firstDay, default: 0] += 0

            var dayStart = firstDay
            while dayStart < end {
                // Day boundaries come from the calendar, not from adding 86 400 s (DST days differ).
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }
                let overlapStart = max(start, dayStart)
                let overlapEnd = min(end, nextDay)
                if overlapEnd > overlapStart {
                    totals[dayStart, default: 0] += overlapEnd.timeIntervalSince(overlapStart)
                }
                dayStart = nextDay
            }
        }

        return totals.keys.sorted(by: >).map { day in
            DayGroup(
                day: day,
                entries: (listed[day] ?? []).sorted { $0.start > $1.start },
                total: totals[day] ?? 0,
                asOf: now,
                isLive: hasRunning && day == today
            )
        }
    }
}
