import Foundation
import SQLite3
import Testing
@testable import TimeTrackerCore

struct SQLiteExporterTests {
    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).sqlite")
    }

    private func row(end: Date? = at(10), title: String = "созвон", notes: String = "") -> ExportRow {
        ExportRow(
            start: at(9), end: end, durationSeconds: 3600,
            category: "Работа", tags: ["a", "b"], title: title, notes: notes
        )
    }

    private func query(_ url: URL, _ sql: String) throws -> [[String?]] {
        var db: OpaquePointer?
        try #require(sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK)
        defer { sqlite3_close(db) }
        var statement: OpaquePointer?
        try #require(sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK)
        defer { sqlite3_finalize(statement) }
        var rows: [[String?]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            rows.append((0..<sqlite3_column_count(statement)).map { column in
                sqlite3_column_text(statement, column).map { String(cString: $0) }
            })
        }
        return rows
    }

    @Test func writesRowsWithSameColumns() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try SQLiteExporter.write([row(), row(end: nil, title: "идёт")], to: url)
        let columns = try query(url, "SELECT name FROM pragma_table_info('entries') ORDER BY cid")
        #expect(columns.compactMap(\.first) == ["start", "end", "duration_seconds", "category", "tags", "title", "notes"])
        let rows = try query(url, "SELECT * FROM entries ORDER BY rowid")
        #expect(rows[0] == ["2027-01-15T09:00:00Z", "2027-01-15T10:00:00Z", "3600", "Работа", "a;b", "созвон", ""])
        #expect(rows[1][1] == nil)
        #expect(rows[1][5] == "идёт")
    }

    @Test func userVersionIsOne() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try SQLiteExporter.write([], to: url)
        #expect(try query(url, "PRAGMA user_version") == [["1"]])
    }

    @Test func overwritesExistingFile() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try SQLiteExporter.write([row(), row()], to: url)
        try SQLiteExporter.write([row()], to: url)
        #expect(try query(url, "SELECT count(*) FROM entries") == [["1"]])
    }

    @Test func storesTextVerbatimWithoutCSVEscaping() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let title = "=SUM(A1), \"quoted\"\nline 🏃"
        try SQLiteExporter.write([row(title: title, notes: "'; DROP TABLE entries; --")], to: url)
        let stored = try query(url, "SELECT title, notes FROM entries")
        #expect(stored == [[title, "'; DROP TABLE entries; --"]])
    }

    @Test func throwsWhenFileCannotBeCreated() {
        let url = URL(fileURLWithPath: "/nonexistent-directory/file.sqlite")
        #expect(throws: SQLiteExportError.self) {
            try SQLiteExporter.write([row()], to: url)
        }
    }
}
