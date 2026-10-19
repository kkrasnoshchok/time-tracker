import Foundation
import Testing
@testable import TimeTrackerCore

@MainActor
struct PalettePromptTests {
    private let time = TestTimeProvider(at(10))
    private let store: TimeStore
    private let work: EntryCategory

    init() throws {
        store = try TimeStore.inMemory(time: time)
        work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
    }

    private func makeViewModel(input: String) -> PaletteViewModel {
        let viewModel = PaletteViewModel(store: store)
        viewModel.input = input
        return viewModel
    }

    @Test func enterOnKnownCategoryStartsWithoutPrompt() {
        let viewModel = makeViewModel(input: "Работа созвон")
        #expect(viewModel.enter() == .started)
        #expect(viewModel.prompt == nil)
    }

    @Test func enterOnUnknownCategoryAsksBeforeCreating() {
        let viewModel = makeViewModel(input: "Йога утро")
        #expect(viewModel.enter() == .needsCategoryCreation("Йога"))
        #expect(viewModel.prompt == .createCategory("Йога"))
        #expect(store.categories().count == 1)
        #expect(store.runningEntry() == nil)
    }

    @Test func secondEnterCreatesCategoryAndStarts() throws {
        let viewModel = makeViewModel(input: "Йога утро")
        viewModel.enter()
        #expect(viewModel.enter() == .started)
        #expect(viewModel.prompt == nil)
        #expect(store.categories().map(\.name) == ["Работа", "Йога"])
        #expect(try #require(store.runningEntry()).title == "утро")
    }

    @Test func createdCategoryColorComesFromThePalette() throws {
        let viewModel = makeViewModel(input: "Йога")
        viewModel.enter()
        viewModel.enter()
        let created = try #require(store.categories().last)
        #expect(PaletteViewModel.categoryColors.contains(created.colorHex))
    }

    @Test func enterOnOverlapAsksThenSecondEnterForces() throws {
        time.current = at(12)
        try store.addEntry(
            span: TimeSpan(start: at(10), end: at(11)), category: work, title: nil, tags: [], notes: nil
        )
        let viewModel = makeViewModel(input: "Работа -90m")
        #expect(viewModel.enter() == .overlap(store.entries(from: at(0), to: at(23)).map(\.id)))
        #expect(viewModel.prompt == .overlap(count: 1))
        #expect(store.runningEntry() == nil)
        #expect(viewModel.enter() == .started)
        #expect(viewModel.prompt == nil)
        #expect(store.runningEntry() != nil)
    }

    @Test func failureBecomesAnErrorPromptAndKeepsInput() throws {
        try store.startTimer(category: work, title: nil, tags: [])
        time.current = at(10, 30)
        let viewModel = makeViewModel(input: "Работа -45m")
        #expect(viewModel.enter() == .failed(.endBeforeStart))
        #expect(viewModel.prompt == .error(StoreError.endBeforeStart.message))
        #expect(viewModel.input == "Работа -45m")
    }

    @Test func editingInputClearsThePrompt() {
        let viewModel = makeViewModel(input: "Йога")
        viewModel.enter()
        viewModel.input = "Йога утро"
        #expect(viewModel.prompt == nil)
    }

    @Test func thirdKindOfEnterAfterEditingStartsOverInsteadOfConfirming() {
        let viewModel = makeViewModel(input: "Йога")
        viewModel.enter()
        viewModel.input = "Спорт"
        #expect(viewModel.enter() == .needsCategoryCreation("Спорт"))
        #expect(viewModel.prompt == .createCategory("Спорт"))
        #expect(store.categories().count == 1)
    }

    @Test func cancelPromptDismissesAndReportsIt() {
        let viewModel = makeViewModel(input: "Йога")
        viewModel.enter()
        #expect(viewModel.cancelPrompt() == true)
        #expect(viewModel.prompt == nil)
        #expect(viewModel.input == "Йога")
    }

    @Test func cancelPromptWithoutPromptReportsFalse() {
        #expect(makeViewModel(input: "Работа").cancelPrompt() == false)
    }

    @Test func emptyEnterStopsAndClearsAnyPrompt() throws {
        try store.startTimer(category: work, title: nil, tags: [])
        let viewModel = makeViewModel(input: "")
        #expect(viewModel.enter() == .stopped)
        #expect(viewModel.prompt == nil)
    }

    /// SwiftUI's TextField writes its text back to the binding on Enter, right before `onSubmit`.
    /// That unchanged write must not dismiss the question the first Enter just raised.
    @Test func writingTheSameInputBackKeepsThePrompt() {
        let viewModel = makeViewModel(input: "Йога утро")
        viewModel.enter()
        viewModel.input = "Йога утро"
        #expect(viewModel.prompt == .createCategory("Йога"))
        #expect(viewModel.enter() == .started)
        #expect(store.categories().map(\.name) == ["Работа", "Йога"])
    }

    @Test func resetClearsInputPromptAndItems() throws {
        try store.startTimer(category: work, title: nil, tags: [])
        let viewModel = makeViewModel(input: "Йога")
        viewModel.enter()
        viewModel.reset()
        #expect(viewModel.input.isEmpty)
        #expect(viewModel.prompt == nil)
        #expect(viewModel.items == [.stopCurrent])
    }
}
