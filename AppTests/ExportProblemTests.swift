import Foundation
import Testing
@testable import TimeTracker

struct ExportProblemTests {
    private struct DiskFull: LocalizedError {
        var errorDescription: String? { "диск заполнен" }
    }

    @Test func messageNamesTheExportAndTheReason() {
        #expect(ExportProblem.message(DiskFull()) == "Не удалось экспортировать: диск заполнен")
    }

    @Test func messageFallsBackToTheSystemDescription() {
        let error = NSError(domain: "x", code: 1, userInfo: [NSLocalizedDescriptionKey: "no access"])
        #expect(ExportProblem.message(error) == "Не удалось экспортировать: no access")
    }
}
