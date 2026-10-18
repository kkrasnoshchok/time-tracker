import Foundation
import Testing
@testable import TimeTrackerCore

@MainActor
struct TimeStoreEntryTests {
    private let time = TestTimeProvider(at(10))
    private let store: TimeStore
    private let work: EntryCategory
    private let study: EntryCategory

    init() throws {
        store = try TimeStore.inMemory(time: time)
        work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        study = try store.addCategory(name: "Учёба", colorHex: "#30D158")
    }

    private func span(_ start: Date, _ end: Date?) throws -> TimeSpan {
        try TimeSpan(start: start, end: end)
    }

    @discardableResult
    private func addClosed(_ start: Date, _ end: Date, title: String? = nil) throws -> TimeEntry {
        try store.addEntry(
            span: span(start, end), category: work, title: title, tags: [], notes: nil, allowOverlap: true
        )
    }

    // MARK: Timer

    @Test func startCreatesRunningEntry() throws {
        let entry = try store.startTimer(category: work, title: "  созвон  ", tags: ["a", "A", "b"])
        #expect(entry.start == at(10))
        #expect(entry.end == nil)
        #expect(entry.title == "созвон")
        #expect(entry.category === work)
        #expect(entry.tagList.map(\.name).sorted() == ["a", "b"])
        #expect(store.runningEntry() === entry)
    }

    @Test func blankTitleIsStoredAsNil() throws {
        let entry = try store.startTimer(category: work, title: "   ", tags: [])
        #expect(entry.title == nil)
    }

    @Test func secondStartStopsPreviousAtNewStart() throws {
        let first = try store.startTimer(category: work, title: nil, tags: [])
        time.current = at(10, 30)
        let second = try store.startTimer(category: study, title: nil, tags: [])
        #expect(first.end == at(10, 30))
        #expect(second.end == nil)
        #expect(store.runningEntry() === second)
    }

    @Test func startWithOffsetStopsPreviousAtOffsetStart() throws {
        let first = try store.startTimer(category: work, title: nil, tags: [])
        time.current = at(10, 30)
        let second = try store.startTimer(category: study, title: nil, tags: [], startedAt: at(10, 10))
        #expect(first.end == at(10, 10))
        #expect(second.start == at(10, 10))
    }

    @Test func startBeforeRunningStartThrowsAndKeepsRunningTimer() throws {
        let first = try store.startTimer(category: work, title: nil, tags: [])
        time.current = at(10, 30)
        #expect(throws: StoreError.endBeforeStart) {
            try store.startTimer(category: study, title: nil, tags: [], startedAt: at(9, 50))
        }
        #expect(first.end == nil)
        #expect(store.runningEntry() === first)
    }

    @Test func startInFutureThrows() {
        #expect(throws: StoreError.startInFuture) {
            try store.startTimer(category: work, title: nil, tags: [], startedAt: at(10, 5))
        }
        #expect(store.runningEntry() == nil)
    }

    @Test func startWithOffsetOverlappingClosedEntryThrowsUnlessAllowed() throws {
        time.current = at(12)
        let closed = try addClosed(at(10), at(11))
        #expect(throws: StoreError.overlap([closed.id])) {
            try store.startTimer(category: work, title: nil, tags: [], startedAt: at(10, 30))
        }
        #expect(store.runningEntry() == nil)
        let forced = try store.startTimer(category: work, title: nil, tags: [], startedAt: at(10, 30), allowOverlap: true)
        #expect(store.runningEntry() === forced)
    }

    @Test func stopSetsEndToNow() throws {
        let entry = try store.startTimer(category: work, title: nil, tags: [])
        time.current = at(10, 45)
        let stopped = try store.stopTimer()
        #expect(stopped === entry)
        #expect(entry.end == at(10, 45))
        #expect(store.runningEntry() == nil)
    }

    @Test func stopWhenClockWentBackNeverProducesEndBeforeStart() throws {
        let entry = try store.startTimer(category: work, title: nil, tags: [])
        time.current = at(9, 55)
        try store.stopTimer()
        #expect(entry.end == at(10))
    }

    @Test func stopWithoutRunningThrows() {
        #expect(throws: StoreError.noRunningTimer) {
            try store.stopTimer()
        }
    }

    @Test func runningTimerSurvivesContainerRecreation() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")

        var first: TimeStore? = try TimeStore(container: TimeStore.makeContainer(storeURL: url), time: time)
        let category = try #require(first).addCategory(name: "Работа", colorHex: "#0A84FF")
        try #require(first).startTimer(category: category, title: "долгая задача", tags: [])
        first = nil

        let second = try TimeStore(container: TimeStore.makeContainer(storeURL: url), time: time)
        let running = try #require(second.runningEntry())
        #expect(running.title == "долгая задача")
        #expect(running.end == nil)
    }

    // MARK: Manual entries

    @Test func addEntryStoresAllFields() throws {
        time.current = at(12)
        let entry = try store.addEntry(
            span: span(at(9), at(10)), category: study, title: "лекция", tags: ["swift"], notes: "заметки", allowOverlap: false
        )
        #expect(entry.start == at(9) && entry.end == at(10))
        #expect(entry.category === study)
        #expect(entry.title == "лекция" && entry.notes == "заметки")
        #expect(entry.tagList.map(\.name) == ["swift"])
    }

    @Test func addEntryRejectsOverlapWithIds() throws {
        time.current = at(12)
        let existing = try addClosed(at(9), at(10))
        #expect(throws: StoreError.overlap([existing.id])) {
            try store.addEntry(span: span(at(9, 30), at(10, 30)), category: work, title: nil, tags: [], notes: nil)
        }
    }

    @Test func addEntryTouchingNeighborIsAllowed() throws {
        time.current = at(12)
        try addClosed(at(9), at(10))
        let touching = try store.addEntry(span: span(at(10), at(11)), category: work, title: nil, tags: [], notes: nil)
        #expect(touching.start == at(10))
    }

    @Test func addEntryAllowOverlapSucceeds() throws {
        time.current = at(12)
        try addClosed(at(9), at(10))
        try store.addEntry(
            span: span(at(9, 30), at(10, 30)), category: work, title: nil, tags: [], notes: nil, allowOverlap: true
        )
        #expect(store.entries(from: at(0), to: at(23)).count == 2)
    }

    @Test func addEntryRejectsOverlapWithRunningTimer() throws {
        let running = try store.startTimer(category: work, title: nil, tags: [])
        time.current = at(11)
        #expect(throws: StoreError.overlap([running.id])) {
            try store.addEntry(span: span(at(10, 20), at(10, 40)), category: work, title: nil, tags: [], notes: nil)
        }
    }

    @Test func addEntryWithFutureStartThrows() throws {
        #expect(throws: StoreError.startInFuture) {
            try store.addEntry(span: span(at(11), at(12)), category: work, title: nil, tags: [], notes: nil)
        }
    }

    @Test func addEntryWithFutureEndThrows() throws {
        #expect(throws: StoreError.endInFuture) {
            try store.addEntry(span: span(at(9), at(11)), category: work, title: nil, tags: [], notes: nil)
        }
    }

    @Test func addEntryWithoutEndIsRejected() throws {
        #expect(throws: StoreError.missingEnd) {
            try store.addEntry(span: span(at(9), nil), category: work, title: nil, tags: [], notes: nil)
        }
    }

    // MARK: Update and delete

    @Test func updateChangesFieldsAndKeepsIdentity() throws {
        time.current = at(12)
        let entry = try addClosed(at(9), at(10), title: "старое")
        let id = entry.id
        try store.update(
            entry, span: span(at(9, 15), at(10, 45)), category: study, title: "новое", tags: ["x"], notes: "описание"
        )
        #expect(entry.id == id)
        #expect(entry.start == at(9, 15) && entry.end == at(10, 45))
        #expect(entry.category === study)
        #expect(entry.title == "новое" && entry.notes == "описание")
        #expect(entry.tagList.map(\.name) == ["x"])
    }

    @Test func updateOverlapCheckExcludesItself() throws {
        time.current = at(12)
        let entry = try addClosed(at(9), at(10))
        try store.update(entry, span: span(at(9, 10), at(10, 10)), category: work, title: nil, tags: [], notes: nil)
        #expect(entry.start == at(9, 10))
    }

    @Test func updateRejectsOverlapWithAnotherEntry() throws {
        time.current = at(12)
        let first = try addClosed(at(9), at(10))
        let second = try addClosed(at(10), at(11))
        #expect(throws: StoreError.overlap([first.id])) {
            try store.update(second, span: span(at(9, 30), at(11)), category: work, title: nil, tags: [], notes: nil)
        }
        #expect(second.start == at(10))
    }

    @Test func updateCannotCreateSecondRunningEntry() throws {
        time.current = at(12)
        let closed = try addClosed(at(8), at(9))
        let running = try store.startTimer(category: work, title: nil, tags: [])
        #expect(throws: StoreError.overlap([running.id])) {
            try store.update(
                closed, span: span(at(8), nil), category: work, title: nil, tags: [], notes: nil, allowOverlap: true
            )
        }
    }

    @Test func deleteRemovesEntry() throws {
        time.current = at(12)
        let entry = try addClosed(at(9), at(10))
        try store.delete(entry)
        #expect(store.entries(from: at(0), to: at(23)).isEmpty)
    }

    // MARK: Queries

    @Test func entriesQueryIncludesEntryCrossingRangeBoundaryAndSortsByStart() throws {
        time.current = at(20)
        try addClosed(at(14), at(15), title: "поздно")
        try addClosed(at(8), at(9, 30), title: "пересекает начало")
        try addClosed(at(1), at(2), title: "до периода")
        let titles = store.entries(from: at(9), to: at(18)).map(\.title)
        #expect(titles == ["пересекает начало", "поздно"])
    }

    @Test func entriesQueryIncludesRunningEntry() throws {
        let running = try store.startTimer(category: work, title: nil, tags: [])
        #expect(store.entries(from: at(0), to: at(23)).first === running)
    }

    @Test func recentTitlesOrderedByFrequencyThenRecency() throws {
        time.current = at(20)
        try addClosed(at(1), at(2), title: "созвон")
        try addClosed(at(2), at(3), title: "код")
        try addClosed(at(3), at(4), title: "созвон")
        try addClosed(at(4), at(5), title: "почта")
        try addClosed(at(5), at(6), title: nil)
        #expect(store.recentTitles(limit: 10) == ["созвон", "почта", "код"])
        #expect(store.recentTitles(limit: 1) == ["созвон"])
    }

    @Test func lastEntryReturnsMostRecentlyStarted() throws {
        time.current = at(20)
        try addClosed(at(1), at(2), title: "раньше")
        let later = try addClosed(at(5), at(6), title: "позже")
        try addClosed(at(3), at(4), title: "между")
        #expect(store.lastEntry() === later)
    }

    @Test func lastEntryIsNilWithoutEntries() {
        #expect(store.lastEntry() == nil)
    }
}
