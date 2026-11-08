import Foundation

/// What the error strip shows when writing an export file fails. Pure, so tests can pin it.
enum ExportProblem {
    static func message(_ error: Error) -> String {
        "Не удалось экспортировать: \(error.localizedDescription)"
    }
}
