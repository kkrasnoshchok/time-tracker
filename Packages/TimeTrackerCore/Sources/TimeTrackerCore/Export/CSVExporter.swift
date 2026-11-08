import Foundation

/// RFC 4180 CSV (CRLF line ends). Text fields that start with `= + - @` or a tab/CR get a leading `'`,
/// so spreadsheets do not run them as formulas.
public enum CSVExporter {
    public static let header = "start,end,duration_seconds,category,tags,title,notes"

    public static func csv(_ rows: [ExportRow]) -> String {
        var lines = [header]
        for row in rows {
            let fields = [
                row.start.formatted(.iso8601),
                row.end?.formatted(.iso8601) ?? "",
                String(row.durationSeconds),
                text(row.category),
                text(row.tags.joined(separator: ";")),
                text(row.title),
                text(row.notes)
            ]
            lines.append(fields.map(quoted).joined(separator: ","))
        }
        return lines.map { $0 + "\r\n" }.joined()
    }

    private static let formulaTriggers: Set<Character> = ["=", "+", "-", "@", "\t", "\r"]

    private static func text(_ value: String) -> String {
        guard let first = value.first, formulaTriggers.contains(first) else { return value }
        return "'" + value
    }

    private static func quoted(_ field: String) -> String {
        // `isNewline` also matches "\r\n", which Swift treats as a single Character.
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
