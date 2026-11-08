import Foundation
import Testing
import TimeTrackerCore
@testable import TimeTracker

struct EntryProblemTests {
    @Test func messageIsTheCoreMessage() {
        #expect(EntryProblem.message(.endBeforeStart) == StoreError.endBeforeStart.message)
    }

    @Test func overlapOffersSaveAnyway() {
        #expect(EntryProblem.actionLabel(.overlap([UUID()])) == "Всё равно")
    }

    @Test func otherErrorsOfferNoAction() {
        let others: [StoreError] = [
            .emptyName, .duplicateName, .categoryHasEntries, .startInFuture, .endInFuture,
            .missingEnd, .endBeforeStart, .noRunningTimer, .notFound, .saveFailed("x")
        ]
        for error in others {
            #expect(EntryProblem.actionLabel(error) == nil)
        }
    }
}
