import Foundation
import Testing
@testable import TimeTrackerCore

@MainActor
struct JournalViewModelTests {
    private let time = TestTimeProvider(at(20))
    private let store: TimeStore
    private let work: EntryCategory
    private let study: EntryCategory
    private let viewModel: JournalViewModel

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    init() throws {
        store = try TimeStore.inMemory(time: time)
        work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        study = try store.addCategory(name: "Учёба", colorHex: "#30D158")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        viewModel = JournalViewModel(store: store, calendar: calendar)
    }

    @discardableResult
    private func add(
        _ start: Date, _ end: Date, _ category: EntryCategory? = nil, title: String? = nil
    ) throws -> TimeEntry {
        try store.addEntry(
            span: TimeSpan(start: start, end: end), category: category ?? work, title: title, tags: [], notes: nil
        )
    }

    private func draft(
        _ start: Date, _ end: Date?, category: EntryCategory? = nil,
        title: String = "", tags: String = "", notes: String = ""
    ) -> EntryDraft {
        EntryDraft(start: start, end: end, categoryID: (category ?? work).id, title: title, tags: tags, notes: notes)
    }

    // MARK: Loading

    @Test func startsEmpty() {
        viewModel.reload()
        #expect(viewModel.groups.isEmpty)
        #expect(viewModel.categories.map(\.name) == ["Работа", "Учёба"])
    }

    @Test func loadsEntriesGroupedNewestDayFirst() throws {
        let earlier = try add(at(9).addingTimeInterval(-86_400), at(10).addingTimeInterval(-86_400))
        let today = try add(at(9), at(10))
        viewModel.reload()
        #expect(viewModel.groups.map(\.entries) == [[today], [earlier]])
    }

    @Test func reloadPicksUpChangesMadeElsewhere() throws {
        viewModel.reload()
        try add(at(9), at(10))
        viewModel.reload()
        #expect(viewModel.groups.count == 1)
    }

    @Test func changingTheFilterReloads() throws {
        let meeting = try add(at(9), at(10), work, title: "созвон")
        try add(at(11), at(12), study, title: "лекция")
        viewModel.filter = EntryFilter(category: work.id)
        #expect(viewModel.groups.flatMap(\.entries) == [meeting])
        viewModel.filter = EntryFilter(text: "лекц")
        #expect(viewModel.groups.flatMap(\.entries).count == 1)
        viewModel.filter = EntryFilter()
        #expect(viewModel.groups.flatMap(\.entries).count == 2)
    }

    // MARK: Drafts

    @Test func draftFromEntryCopiesEveryField() throws {
        let entry = try store.addEntry(
            span: TimeSpan(start: at(9), end: at(10)), category: study, title: "лекция",
            tags: ["б", "а"], notes: "заметки"
        )
        let draft = EntryDraft(entry: entry)
        #expect(draft == EntryDraft(
            start: at(9), end: at(10), categoryID: study.id, title: "лекция", tags: "#а #б", notes: "заметки"
        ))
    }

    @Test func blankDraftCoversTheLastHourEndingNow() {
        let blank = EntryDraft.blank(now: at(15, 30), categoryID: work.id)
        #expect(blank.start == at(14, 30) && blank.end == at(15, 30))
        #expect(blank.categoryID == work.id && blank.title.isEmpty && blank.notes.isEmpty)
    }

    // MARK: Saving

    @Test func savingANewDraftAddsTheEntry() throws {
        let input = draft(at(9), at(10), title: "созвон", tags: "#a, #b", notes: "детали")
        let entry = try viewModel.save(input, to: nil)
        #expect(entry.title == "созвон" && entry.notes == "детали")
        #expect(entry.tagList.map(\.name).sorted() == ["a", "b"])
        #expect(viewModel.groups.flatMap(\.entries) == [entry])
    }

    @Test func savingWithUnknownCategoryThrowsNotFound() {
        let unknown = EntryDraft(start: at(9), end: at(10), categoryID: UUID(), title: "", tags: "", notes: "")
        #expect(throws: StoreError.notFound) {
            try viewModel.save(unknown, to: nil)
        }
        #expect(viewModel.groups.isEmpty)
    }

    @Test func savingWithoutCategoryThrowsNotFound() {
        let none = EntryDraft(start: at(9), end: at(10), categoryID: nil, title: "", tags: "", notes: "")
        #expect(throws: StoreError.notFound) {
            try viewModel.save(none, to: nil)
        }
    }

    @Test func overlapThrowsUnlessAllowed() throws {
        let existing = try add(at(9), at(10))
        #expect(throws: StoreError.overlap([existing.id])) {
            try viewModel.save(draft(at(9, 30), at(10, 30)), to: nil)
        }
        try viewModel.save(draft(at(9, 30), at(10, 30)), to: nil, allowOverlap: true)
        #expect(viewModel.groups.flatMap(\.entries).count == 2)
    }

    @Test func savingAnExistingEntryUpdatesItInPlace() throws {
        let entry = try add(at(9), at(10), work, title: "старое")
        let id = entry.id
        let saved = try viewModel.save(draft(at(9, 15), at(10, 15), category: study, title: "новое"), to: entry)
        #expect(saved === entry && entry.id == id)
        #expect(entry.start == at(9, 15) && entry.category === study && entry.title == "новое")
    }

    @Test func editingTheRunningEntryKeepsItRunning() throws {
        time.current = at(10)
        let running = try store.startTimer(category: work, title: nil, tags: [])
        time.current = at(11)
        try viewModel.save(draft(at(9, 30), nil, title: "поздно запустил"), to: running)
        #expect(running.end == nil && running.start == at(9, 30) && running.title == "поздно запустил")
        #expect(store.runningEntry() === running)
    }

    @Test func failedUpdateLeavesTheEntryUntouched() throws {
        let entry = try add(at(9), at(10))
        #expect(throws: StoreError.startInFuture) {
            try viewModel.save(draft(at(21), at(22)), to: entry)
        }
        #expect(entry.start == at(9))
    }

    @Test func deleteRemovesAndReloads() throws {
        let entry = try add(at(9), at(10))
        viewModel.reload()
        try viewModel.delete(entry)
        #expect(viewModel.groups.isEmpty)
    }

    // MARK: Export, categories

    @Test func exportRowsFollowTheFilter() throws {
        try add(at(9), at(10), work, title: "работа")
        try add(at(11), at(12), study, title: "учёба")
        viewModel.filter = EntryFilter(category: study.id)
        let rows = viewModel.exportRows()
        #expect(rows.map(\.title) == ["учёба"])
        #expect(rows.first?.durationSeconds == 3600)
    }

    @Test func exportRowsAreOldestFirst() throws {
        try add(at(11), at(12), title: "позже")
        try add(at(9), at(10), title: "раньше")
        viewModel.reload()
        #expect(viewModel.exportRows().map(\.title) == ["раньше", "позже"])
    }

    @Test func deletingACategoryWithEntriesMovesThemAndReloads() throws {
        try add(at(9), at(10), work)
        viewModel.reload()
        try viewModel.deleteCategory(work, movingEntriesTo: study)
        #expect(viewModel.categories.map(\.name) == ["Учёба"])
        #expect(viewModel.groups.flatMap(\.entries).first?.category === study)
    }

    @Test func tagsListIncludesTagsCreatedBySaving() throws {
        try viewModel.save(draft(at(9), at(10), tags: "#x #y"), to: nil)
        #expect(viewModel.tags.map(\.name) == ["x", "y"])
    }
}
