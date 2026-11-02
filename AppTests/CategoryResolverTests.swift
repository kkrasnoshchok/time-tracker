import SwiftUI
import Testing
@testable import TimeTracker

struct CategoryResolverTests {
    private let names = ["Работа", "Учёба", "Deep Work", "Deep"]

    @Test func matchingNameFollowedBySpaceSplitsPrefixAndRest() {
        let split = CategoryResolver.split("Работа отчёт #ops -20m", among: names)

        #expect(split?.name == "Работа")
        #expect(split?.prefix == "Работа ")
        #expect(split?.rest == "отчёт #ops -20m")
    }

    @Test func noMatchGivesNoToken() {
        #expect(CategoryResolver.split("Отдых кино", among: names) == nil)
    }

    @Test func nameWithoutFollowingSpaceIsStillPlainText() {
        #expect(CategoryResolver.split("Работа", among: names) == nil)
        #expect(CategoryResolver.split("Работать", among: names) == nil)
    }

    @Test func caseDifferenceStillMatchesAndKeepsTypedPrefix() {
        let split = CategoryResolver.split("рАБОТА x", among: names)

        #expect(split?.name == "Работа")
        #expect(split?.prefix == "рАБОТА ")
        #expect(split?.rest == "x")
    }

    @Test func emptyAndBlankLinesGiveNoToken() {
        #expect(CategoryResolver.split("", among: names) == nil)
        #expect(CategoryResolver.split("   ", among: names) == nil)
    }

    @Test func unicodeNamesMatch() {
        #expect(CategoryResolver.split("учёба  лекция", among: names)?.name == "Учёба")
        #expect(CategoryResolver.split("🏃 бег", among: ["🏃"])?.name == "🏃")
    }

    @Test func longestNameWins() {
        let split = CategoryResolver.split("Deep Work план", among: names)

        #expect(split?.name == "Deep Work")
        #expect(split?.rest == "план")
    }

    @Test func prefixPlusRestIsAlwaysTheOriginalInput() {
        for input in ["Работа  два пробела", "  Работа x", "Работа "] {
            let split = CategoryResolver.split(input, among: names)
            #expect((split?.prefix ?? "") + (split?.rest ?? input) == input)
        }
    }

    @Test func backspaceAtTheStartOfTheRestDeletesTheSeparatorSoTheTokenDissolves() {
        let split = CategoryResolver.split("Работа отчёт", among: names)

        #expect(split?.inputAfterBackspace == "Работаотчёт")
        #expect(CategoryResolver.split("Работаотчёт", among: names) == nil)
    }

    @Test func backspaceWithAnEmptyRestLeavesTheNameAsPlainText() {
        let split = CategoryResolver.split("Работа ", among: names)

        #expect(split?.inputAfterBackspace == "Работа")
    }
}

struct TagMutingTests {
    private func mutedWords(in text: String) -> [String] {
        let attributed = PaletteView.mutingTags(in: text)
        return attributed.runs
            .filter { $0.foregroundColor == Color.textTertiary }
            .map { String(attributed[$0.range].characters) }
    }

    @Test func onlyTagWordsAreMuted() {
        #expect(mutedWords(in: "отчёт #ops #дом -20m") == ["#ops", "#дом"])
    }

    @Test func aLoneHashAndPlainTextAreNotMuted() {
        #expect(mutedWords(in: "# отчёт a#b").isEmpty)
        #expect(mutedWords(in: "").isEmpty)
    }
}

struct TokenEditingTests {
    private let names = ["Работа"]

    private func split(_ input: String) -> CategoryResolver.Split {
        CategoryResolver.split(input, among: names)!
    }

    @Test func fieldTextStartsWithTheAnchorSoBackspaceHasSomethingToDelete() {
        let text = CategoryResolver.fieldText(for: split("Работа отчёт"))

        #expect(text == CategoryResolver.anchor + "отчёт")
    }

    @Test func typingKeepsThePrefix() {
        let s = split("Работа отчёт")
        let edited = CategoryResolver.input(afterEditing: CategoryResolver.anchor + "отчёты", split: s)

        #expect(edited == "Работа отчёты")
    }

    @Test func deletingTheAnchorDissolvesTheToken() {
        let s = split("Работа отчёт")

        #expect(CategoryResolver.input(afterEditing: "отчёт", split: s) == "Работаотчёт")
    }

    @Test func deletingTheAnchorWithAnEmptyRestDissolvesTheToken() {
        let s = split("Работа ")

        #expect(CategoryResolver.input(afterEditing: "", split: s) == "Работа")
    }

    @Test func replacingEverythingKeepsTheTokenAndStripsAnyAnchor() {
        let s = split("Работа отчёт")

        #expect(CategoryResolver.input(afterEditing: "план", split: s) == "Работа план")
    }

    @Test func pastedAnchorsAreStripped() {
        let s = split("Работа ")
        let pasted = CategoryResolver.anchor + "a" + CategoryResolver.anchor + "b"

        #expect(CategoryResolver.input(afterEditing: pasted, split: s) == "Работа ab")
    }
}
