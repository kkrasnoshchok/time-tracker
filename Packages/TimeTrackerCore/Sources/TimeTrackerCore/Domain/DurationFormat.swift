import Foundation

public enum DurationFormat {
    /// Running-timer style: `0:42`, `12:05`, `1:02:05`. Negative values show as zero.
    public static func clock(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let hours = total / 3600
        let minutes = total % 3600 / 60
        let seconds = total % 60
        let paddedSeconds = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        if hours > 0 {
            let paddedMinutes = minutes < 10 ? "0\(minutes)" : "\(minutes)"
            return "\(hours):\(paddedMinutes):\(paddedSeconds)"
        }
        return "\(minutes):\(paddedSeconds)"
    }

    /// Journal style: `45 мин`, `1 ч`, `1 ч 30 мин`. Seconds are dropped.
    public static func short(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let hours = total / 3600
        let minutes = total % 3600 / 60
        if hours == 0 { return "\(minutes) мин" }
        return minutes == 0 ? "\(hours) ч" : "\(hours) ч \(minutes) мин"
    }
}
