import Foundation
import Testing
@testable import TimeTrackerCore

struct JournalSelectionTests {
    private let first = UUID(), second = UUID(), third = UUID()
    private var ids: [UUID] { [first, second, third] }

    @Test func emptyListHasNoMove() {
        #expect(JournalSelection.next(from: nil, in: [], step: 1) == nil)
        #expect(JournalSelection.next(from: first, in: [], step: -1) == nil)
    }

    @Test func nothingSelectedDownPicksFirst() {
        #expect(JournalSelection.next(from: nil, in: ids, step: 1) == first)
    }

    @Test func nothingSelectedUpPicksLast() {
        #expect(JournalSelection.next(from: nil, in: ids, step: -1) == third)
    }

    @Test func movesToNeighbour() {
        #expect(JournalSelection.next(from: second, in: ids, step: 1) == third)
        #expect(JournalSelection.next(from: second, in: ids, step: -1) == first)
    }

    @Test func clampsAtBothEnds() {
        #expect(JournalSelection.next(from: third, in: ids, step: 1) == third)
        #expect(JournalSelection.next(from: first, in: ids, step: -1) == first)
    }

    @Test func staleSelectionBehavesLikeNoSelection() {
        let gone = UUID()
        #expect(JournalSelection.next(from: gone, in: ids, step: 1) == first)
        #expect(JournalSelection.next(from: gone, in: ids, step: -1) == third)
    }

    @Test func singleEntryStaysPut() {
        #expect(JournalSelection.next(from: first, in: [first], step: 1) == first)
        #expect(JournalSelection.next(from: first, in: [first], step: -1) == first)
    }
}
