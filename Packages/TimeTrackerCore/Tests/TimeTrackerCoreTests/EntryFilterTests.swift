import Foundation
import Testing
@testable import TimeTrackerCore

@MainActor
struct EntryFilterTests {
    private let time = TestTimeProvider(at(23))
    private let store: TimeStore
    private let work: EntryCategory
    private let study: EntryCategory
    private let meeting: TimeEntry
    private let reading: TimeEntry

    init() throws {
        store = try TimeStore.inMemory(time: time)
        work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        study = try store.addCategory(name: "Учёба", colorHex: "#30D158")
        meeting = try store.addEntry(
            span: TimeSpan(start: at(9), end: at(10)), category: work, title: "Созвон с клиентом",
            tags: ["клиентX", "созвон"], notes: "обсудили бюджет"
        )
        reading = try store.addEntry(
            span: TimeSpan(start: at(14), end: at(15)), category: study, title: "Книга по Swift",
            tags: ["swift"], notes: nil
        )
    }

    private func matches(_ filter: EntryFilter) -> [TimeEntry] {
        [meeting, reading].filter { filter.matches($0) }
    }

    @Test func defaultFilterMatchesEverything() {
        #expect(matches(EntryFilter()) == [meeting, reading])
    }

    @Test func filterByCategory() {
        #expect(matches(EntryFilter(category: study.id)) == [reading])
    }

    @Test func filterByTag() throws {
        let tag = try #require(store.tags().first { $0.name == "созвон" })
        #expect(matches(EntryFilter(tag: tag.id)) == [meeting])
    }

    @Test func textMatchesTitleNotesAndTagsIgnoringCase() {
        #expect(matches(EntryFilter(text: "КЛИЕНТОМ")) == [meeting])
        #expect(matches(EntryFilter(text: "бюджет")) == [meeting])
        #expect(matches(EntryFilter(text: "SWIFT")) == [reading])
        #expect(matches(EntryFilter(text: "клиентx")) == [meeting])
        #expect(matches(EntryFilter(text: "нет такого")).isEmpty)
    }

    @Test func blankTextMatchesEverything() {
        #expect(matches(EntryFilter(text: "   ")) == [meeting, reading])
    }

    @Test func rangeUsesStartAndExcludesTheEnd() {
        #expect(matches(EntryFilter(from: at(9), to: at(14))) == [meeting])
        #expect(matches(EntryFilter(from: at(9, 1), to: at(15))) == [reading])
        #expect(matches(EntryFilter(from: at(15))).isEmpty)
    }

    @Test func combinedFiltersAreAnded() {
        #expect(matches(EntryFilter(category: work.id, text: "swift")).isEmpty)
        #expect(matches(EntryFilter(category: work.id, text: "созвон", from: at(8), to: at(12))) == [meeting])
    }
}
