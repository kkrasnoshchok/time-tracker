import AppKit
import TimeTrackerCore
import UniformTypeIdentifiers

/// Save-panel wrappers around the exporters from `TimeTrackerCore`.
@MainActor
enum ExportActions {
    static func exportCSV(_ rows: [ExportRow]) {
        guard let url = askForFile(name: "time-tracker.csv", type: .commaSeparatedText) else { return }
        do {
            try CSVExporter.csv(rows).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            show(error)
        }
    }

    static func exportSQLite(_ rows: [ExportRow]) {
        let sqlite = UTType(filenameExtension: "sqlite") ?? .data
        guard let url = askForFile(name: "time-tracker.sqlite", type: sqlite) else { return }
        do {
            try SQLiteExporter.write(rows, to: url)
        } catch {
            show(error)
        }
    }

    private static func askForFile(name: String, type: UTType) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = name
        panel.allowedContentTypes = [type]
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func show(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Не удалось экспортировать"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}
