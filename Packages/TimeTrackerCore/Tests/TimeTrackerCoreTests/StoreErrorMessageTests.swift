import Foundation
import Testing
@testable import TimeTrackerCore

struct StoreErrorMessageTests {
    @Test(arguments: [
        StoreError.emptyName, .duplicateName, .categoryHasEntries, .startInFuture, .endInFuture,
        .missingEnd, .endBeforeStart, .overlap([UUID()]), .noRunningTimer, .notFound, .saveFailed("диск")
    ])
    func everyErrorHasAReadableMessage(error: StoreError) {
        #expect(!error.message.isEmpty)
    }

    @Test func overlapMessageMentionsHowManyEntriesClash() {
        #expect(StoreError.overlap([UUID(), UUID()]).message.contains("2"))
    }

    @Test func saveFailedIncludesTheUnderlyingReason() {
        #expect(StoreError.saveFailed("диск полон").message.contains("диск полон"))
    }

    @Test func differentErrorsHaveDifferentMessages() {
        #expect(StoreError.endBeforeStart.message != StoreError.startInFuture.message)
    }
}
