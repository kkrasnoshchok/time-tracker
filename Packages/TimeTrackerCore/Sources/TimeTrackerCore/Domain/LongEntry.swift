import Foundation

/// The «долго» rule: an entry of 8 hours or more is probably a forgotten timer.
/// A pure function of its inputs, like a TS helper taking `now` as an argument.
public enum LongEntry {
    public static let threshold: TimeInterval = 8 * 3600

    /// Finished entries use `end − start`, running ones `now − start`.
    /// The full duration counts, even when the entry spans midnight.
    public static func isLong(start: Date, end: Date?, now: Date) -> Bool {
        let duration = end.map { $0.timeIntervalSince(start) } ?? now.timeIntervalSince(start)
        return duration >= threshold
    }
}
