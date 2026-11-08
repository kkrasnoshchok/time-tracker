import Foundation

public enum TimeSpanError: Error, Equatable {
    case endBeforeStart
}

/// A half-open interval `[start, end)`. A span without `end` is still running.
public struct TimeSpan: Equatable, Sendable {
    public let start: Date
    public let end: Date?

    public init(start: Date, end: Date?) throws(TimeSpanError) {
        if let end, end < start { throw .endBeforeStart }
        self.start = start
        self.end = end
    }

    /// Two spans overlap when each starts before the other ends; touching spans do not.
    /// A running span is treated as ending at `now`.
    public func overlaps(_ other: TimeSpan, now: Date) -> Bool {
        start < other.end ?? now && other.start < end ?? now
    }

    public func duration(now: Date) -> TimeInterval {
        max(0, (end ?? now).timeIntervalSince(start))
    }
}
