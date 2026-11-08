import AppKit
import TimeTrackerCore
import UniformTypeIdentifiers

/// Save-panel wrappers around the exporters from `TimeTrackerCore`.
@MainActor
enum ExportActions {
    /// Both return the problem text for the caller's error strip, or `nil` when the file
    /// was written or the person cancelled the save panel.
    static func exportCSV(_ rows: [ExportRow]) -> String? {
        guard let url = askForFile(name: "time-tracker.csv", type: .commaSeparatedText) else { return nil }
        do {
            try CSVExporter.csv(rows).write(to: url, atomically: true, encoding: .utf8)
            return nil
        } catch {
            return ExportProblem.message(error)
        }
    }

    static func exportSQLite(_ rows: [ExportRow]) -> String? {
        let sqlite = UTType(filenameExtension: "sqlite") ?? .data
        guard let url = askForFile(name: "time-tracker.sqlite", type: sqlite) else { return nil }
        do {
            try SQLiteExporter.write(rows, to: url)
            return nil
        } catch {
            return ExportProblem.message(error)
        }
    }

    private static func askForFile(name: String, type: UTType) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = name
        panel.allowedContentTypes = [type]
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

}
