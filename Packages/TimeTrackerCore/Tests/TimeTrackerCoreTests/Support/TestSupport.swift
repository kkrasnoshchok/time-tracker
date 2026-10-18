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

/// Minimal RFC 4180 reader, used to prove exported CSV can be read back losslessly.
func parseCSV(_ text: String) -> [[String]] {
    var rows: [[String]] = []
    var row: [String] = []
    var field = ""
    var inQuotes = false
    var characters = Array(text.unicodeScalars)[...]
    while let scalar = characters.popFirst() {
        if inQuotes {
            if scalar == "\"" {
                if characters.first == "\"" {
                    field.unicodeScalars.append("\"")
                    characters.removeFirst()
                } else {
                    inQuotes = false
                }
            } else {
                field.unicodeScalars.append(scalar)
            }
        } else if scalar == "\"" {
            inQuotes = true
        } else if scalar == "," {
            row.append(field)
            field = ""
        } else if scalar == "\r", characters.first == "\n" {
            characters.removeFirst()
            row.append(field)
            rows.append(row)
            row = []
            field = ""
        } else {
            field.unicodeScalars.append(scalar)
        }
    }
    return rows
}
