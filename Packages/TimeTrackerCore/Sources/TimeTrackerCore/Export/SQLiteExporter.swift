import Foundation
import SQLite3

public enum SQLiteExportError: Error, Equatable {
    case openFailed(String)
    case statementFailed(String)
}

/// Writes a fresh SQLite file with one `entries` table (same columns as the CSV), `user_version` = 1.
/// Text is stored verbatim; only the CSV export neutralises spreadsheet formulas.
public enum SQLiteExporter {
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    public static func write(_ rows: [ExportRow], to url: URL) throws {
        try? FileManager.default.removeItem(at: url)
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE
        guard sqlite3_open_v2(url.path, &db, flags, nil) == SQLITE_OK else {
            let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "cannot open database"
            sqlite3_close(db)
            throw SQLiteExportError.openFailed(message)
        }
        defer { sqlite3_close(db) }

        do {
            try execute(db, "PRAGMA user_version = 1")
            try execute(db, """
                CREATE TABLE entries (
                    start TEXT NOT NULL,
                    "end" TEXT,
                    duration_seconds INTEGER NOT NULL,
                    category TEXT NOT NULL,
                    tags TEXT NOT NULL,
                    title TEXT NOT NULL,
                    notes TEXT NOT NULL
                )
                """)
            try execute(db, "BEGIN")
            try insert(rows, into: db)
            try execute(db, "COMMIT")
        } catch {
            sqlite3_exec(db, "ROLLBACK", nil, nil, nil)
            throw error
        }
    }

    private static func insert(_ rows: [ExportRow], into db: OpaquePointer?) throws {
        var statement: OpaquePointer?
        let sql = "INSERT INTO entries VALUES (?, ?, ?, ?, ?, ?, ?)"
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteExportError.statementFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }

        for row in rows {
            sqlite3_reset(statement)
            sqlite3_bind_text(statement, 1, row.start.formatted(.iso8601), -1, transient)
            if let end = row.end {
                sqlite3_bind_text(statement, 2, end.formatted(.iso8601), -1, transient)
            } else {
                sqlite3_bind_null(statement, 2)
            }
            sqlite3_bind_int64(statement, 3, Int64(row.durationSeconds))
            sqlite3_bind_text(statement, 4, row.category, -1, transient)
            sqlite3_bind_text(statement, 5, row.tags.joined(separator: ";"), -1, transient)
            sqlite3_bind_text(statement, 6, row.title, -1, transient)
            sqlite3_bind_text(statement, 7, row.notes, -1, transient)
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw SQLiteExportError.statementFailed(String(cString: sqlite3_errmsg(db)))
            }
        }
    }

    private static func execute(_ db: OpaquePointer?, _ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw SQLiteExportError.statementFailed(String(cString: sqlite3_errmsg(db)))
        }
    }
}
