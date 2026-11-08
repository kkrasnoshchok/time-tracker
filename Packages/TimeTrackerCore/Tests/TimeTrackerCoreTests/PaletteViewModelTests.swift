import Foundation
import Testing
@testable import TimeTrackerCore

@MainActor
struct PaletteViewModelTests {
    private let time = TestTimeProvider(at(10))
    private let store: TimeStore
    private let work: EntryCategory
    private let study: EntryCategory

    init() throws {
        store = try TimeStore.inMemory(time: time)
        work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        study = try store.addCategory(name: "Учёба", colorHex: "#30D158")
    }

    private func makeViewModel(input: String = "") -> PaletteViewModel {
        let viewModel = PaletteViewModel(store: store)
        viewModel.input = input
        return viewModel
    }

    @discardableResult
    private func addClosed(_ start: Date, _ end: Date, title: String?, tags: [String] = []) throws -> TimeEntry {
        try store.addEntry(
            span: TimeSpan(start: start, end: end), category: work, title: title, tags: tags, notes: nil,
            allowOverlap: true
        )
    }

    // MARK: Empty input

    @Test func emptyInputWhileRunningOffersStop() throws {
        try store.startTimer(category: work, title: nil, tags: [])
        #expect(makeViewModel().items == [.stopCurrent])
    }

    @Test func emptySubmitWhileRunningStops() throws {
        try store.startTimer(category: work, title: nil, tags: [])
        time.current = at(10, 20)
        let outcome = makeViewModel().submit()
        #expect(outcome == .stopped)
        #expect(store.runningEntry() == nil)
    }

    @Test func emptyInputWhileIdleOffersRepeatLast() throws {
        time.current = at(12)
        try addClosed(at(9), at(10), title: "созвон")
        #expect(makeViewModel().items == [.repeatLast(title: "созвон", category: "Работа")])
    }

    @Test func emptySubmitWhileIdleRepeatsLastEntryWithItsTags() throws {
        time.current = at(12)
        try addClosed(at(9), at(10), title: "созвон", tags: ["клиентx"])
        let outcome = makeViewModel().submit()
        let running = try #require(store.runningEntry())
        #expect(outcome == .started)
        #expect(running.title == "созвон" && running.category === work)
        #expect(running.tagList.map(\.name) == ["клиентx"])
    }

    @Test func emptySubmitWithNoHistoryDoesNothing() {
        #expect(makeViewModel().submit() == .nothing)
        #expect(store.runningEntry() == nil)
    }

    @Test func whitespaceOnlyInputBehavesAsEmpty() throws {
        try store.startTimer(category: work, title: nil, tags: [])
        #expect(makeViewModel(input: "   ").items == [.stopCurrent])
    }

    @Test func itemsRefreshAfterStopSoRepeatLastAppears() throws {
        try store.startTimer(category: work, title: "созвон", tags: [])
        time.current = at(10, 20)
        let viewModel = makeViewModel()
        viewModel.submit()
        #expect(viewModel.items == [.repeatLast(title: "созвон", category: "Работа")])
    }

    // MARK: Starting

    @Test func submitStartsTimerWithParsedTagsAndTitle() throws {
        let outcome = makeViewModel(input: "Работа созвон #клиентX").submit()
        let running = try #require(store.runningEntry())
        #expect(outcome == .started)
        #expect(running.category === work)
        #expect(running.title == "созвон")
        #expect(running.tagList.map(\.name) == ["клиентx"])
    }

    @Test func successfulSubmitClearsInput() {
        let viewModel = makeViewModel(input: "Работа созвон")
        viewModel.submit()
        #expect(viewModel.input.isEmpty)
    }

    @Test func submitWhileRunningSwitchesTimer() throws {
        let first = try store.startTimer(category: work, title: nil, tags: [])
        time.current = at(10, 30)
        let outcome = makeViewModel(input: "Учёба чтение").submit()
        let running = try #require(store.runningEntry())
        #expect(outcome == .started)
        #expect(first.end == at(10, 30))
        #expect(running !== first && running.category === study)
    }

    @Test func submitWithOffsetStartsInThePast() throws {
        time.current = at(10, 30)
        makeViewModel(input: "Работа -20m").submit()
        #expect(try #require(store.runningEntry()).start == at(10, 10))
    }

    // MARK: Unknown category

    @Test func submitWithUnknownCategoryDoesNotCreateIt() {
        let viewModel = makeViewModel(input: "Йога утро")
        #expect(viewModel.items == [.createCategory("Йога")])
        #expect(viewModel.submit() == .needsCategoryCreation("Йога"))
        #expect(store.categories().count == 2)
        #expect(store.runningEntry() == nil)
        #expect(viewModel.input == "Йога утро")
    }

    @Test func createCategoryAndSubmitCreatesThenStarts() throws {
        let viewModel = makeViewModel(input: "Йога утро #здоровье")
        let outcome = viewModel.createCategoryAndSubmit(colorHex: "#FF9F0A")
        let running = try #require(store.runningEntry())
        #expect(outcome == .started)
        #expect(store.categories().map(\.name) == ["Работа", "Учёба", "Йога"])
        #expect(running.category?.name == "Йога" && running.title == "утро")
    }

    @Test func createCategoryAndSubmitOnKnownCategoryJustStarts() throws {
        let outcome = makeViewModel(input: "Работа").createCategoryAndSubmit(colorHex: "#FF9F0A")
        #expect(outcome == .started)
        #expect(store.categories().count == 2)
    }

    // MARK: Errors

    @Test func submitWithOffsetBeforeRunningStartReportsFailedAndKeepsInput() throws {
        try store.startTimer(category: work, title: nil, tags: [])
        time.current = at(10, 30)
        let viewModel = makeViewModel(input: "Учёба -45m")
        #expect(viewModel.submit() == .failed(.endBeforeStart))
        #expect(viewModel.input == "Учёба -45m")
        #expect(store.runningEntry()?.category === work)
    }

    @Test func overlapIsReportedAndCanBeForced() throws {
        time.current = at(12)
        let closed = try addClosed(at(10), at(11), title: nil)
        let viewModel = makeViewModel(input: "Работа -90m")
        #expect(viewModel.submit() == .overlap([closed.id]))
        #expect(store.runningEntry() == nil)
        #expect(viewModel.submit(allowOverlap: true) == .started)
    }

    // MARK: Items, Tab

    @Test func tabCompletesCategoryName() {
        let viewModel = makeViewModel(input: "раб")
        viewModel.tab()
        #expect(viewModel.input == "Работа ")
    }

    @Test func partialCategoryOffersMatchingCategoryBeforeCreate() {
        #expect(makeViewModel(input: "раб").items == [.suggestion("Работа "), .createCategory("раб")])
    }

    @Test func suggestionsComeFromRecentTitles() throws {
        time.current = at(12)
        try addClosed(at(1), at(2), title: "созвон")
        try addClosed(at(2), at(3), title: "созвон")
        try addClosed(at(3), at(4), title: "создание отчёта")
        try addClosed(at(4), at(5), title: "почта")
        let viewModel = makeViewModel(input: "Работа соз")
        #expect(viewModel.items == [.suggestion("Работа созвон"), .suggestion("Работа создание отчёта")])
        viewModel.tab()
        #expect(viewModel.input == "Работа созвон")
    }

    @Test func suggestionsAreHiddenOnceTagsOrOffsetAreTyped() throws {
        time.current = at(12)
        try addClosed(at(1), at(2), title: "созвон")
        #expect(makeViewModel(input: "Работа соз #a").items.isEmpty)
        #expect(makeViewModel(input: "Работа соз -5m").items.isEmpty)
    }

    @Test func inputChangeRefreshesItems() throws {
        let viewModel = makeViewModel(input: "Йога")
        #expect(viewModel.items == [.createCategory("Йога")])
        viewModel.input = ""
        #expect(viewModel.items.isEmpty)
    }

    @Test func lastEntryWithoutCategoryIsNotOfferedForRepeat() {
        store.context.insert(TimeEntry(start: at(8), end: at(9), title: "сирота"))
        let viewModel = makeViewModel()
        #expect(viewModel.items.isEmpty)
        #expect(viewModel.submit() == .nothing)
        #expect(store.runningEntry() == nil)
    }

    @Test func partialCategoryFollowedByMoreWordsOnlyOffersToCreate() {
        #expect(makeViewModel(input: "раб созвон").items == [.createCategory("раб")])
    }
}
