import Testing
@testable import TimeTrackerCore

struct PaletteParserTests {
    private let work = ["Работа"]

    @Test func parsesCategoryTitleTagsAndOffset() {
        let command = PaletteParser.parse("Работа созвон #клиентX #созвон -20m", knownCategories: work)
        #expect(command == PaletteCommand(
            category: .existing("Работа"),
            title: "созвон",
            tags: ["клиентx", "созвон"],
            startOffset: 1200
        ))
    }

    @Test func caseInsensitiveCategoryReturnsCanonicalName() {
        let command = PaletteParser.parse("работа отчёт", knownCategories: work)
        #expect(command?.category == .existing("Работа"))
        #expect(command?.title == "отчёт")
    }

    @Test func twoWordCategoryWinsOverFirstWord() {
        let command = PaletteParser.parse("deep work чтение", knownCategories: ["Deep Work", "Deep"])
        #expect(command?.category == .existing("Deep Work"))
        #expect(command?.title == "чтение")
    }

    @Test func shorterCategoryUsedWhenLongerDoesNotMatch() {
        let command = PaletteParser.parse("Deep чтение", knownCategories: ["Deep Work", "Deep"])
        #expect(command?.category == .existing("Deep"))
        #expect(command?.title == "чтение")
    }

    @Test func unknownCategoryKeepsFirstWord() {
        let command = PaletteParser.parse("Йога утро", knownCategories: work)
        #expect(command?.category == .unknown("Йога"))
        #expect(command?.title == "утро")
    }

    @Test func categoryAloneHasNoTitleTagsOrOffset() {
        let command = PaletteParser.parse("Работа", knownCategories: work)
        #expect(command == PaletteCommand(category: .existing("Работа"), title: nil, tags: [], startOffset: 0))
    }

    @Test func onlyTagReturnsNil() {
        #expect(PaletteParser.parse("#тег", knownCategories: work) == nil)
    }

    @Test func onlyOffsetReturnsNil() {
        #expect(PaletteParser.parse("-20m", knownCategories: work) == nil)
    }

    @Test func emptyAndWhitespaceReturnNil() {
        #expect(PaletteParser.parse("", knownCategories: work) == nil)
        #expect(PaletteParser.parse("   \t  ", knownCategories: work) == nil)
    }

    @Test func extraWhitespaceIsCollapsed() {
        let command = PaletteParser.parse("  Работа   созвон   с   клиентом  #a  ", knownCategories: work)
        #expect(command?.title == "созвон с клиентом")
        #expect(command?.tags == ["a"])
    }

    @Test func unicodeAndEmojiTitleSurvive() {
        let command = PaletteParser.parse("Спорт 🏃 бег #🔥", knownCategories: ["Спорт"])
        #expect(command?.title == "🏃 бег")
        #expect(command?.tags == ["🔥"])
    }

    @Test func duplicateTagsAreMergedCaseInsensitively() {
        let command = PaletteParser.parse("Работа #A #a #b #A", knownCategories: work)
        #expect(command?.tags == ["a", "b"])
    }

    @Test func hourOffset() {
        #expect(PaletteParser.parse("Работа -2h", knownCategories: work)?.startOffset == 7200)
    }

    @Test func offsetInMiddleIsPartOfTitle() {
        let command = PaletteParser.parse("Работа -20m созвон", knownCategories: work)
        #expect(command?.startOffset == 0)
        #expect(command?.title == "-20m созвон")
    }

    @Test func loneHashIsPlainText() {
        let command = PaletteParser.parse("Работа задача # 5", knownCategories: work)
        #expect(command?.title == "задача # 5")
        #expect(command?.tags == [])
    }

    @Test func completionExtendsUniquePrefix() {
        #expect(PaletteParser.completion(for: "раб", knownCategories: ["Работа", "Спорт"]) == "Работа ")
    }

    @Test func completionPicksFirstOfSeveralMatches() {
        #expect(PaletteParser.completion(for: "Р", knownCategories: ["Работа", "Рисование"]) == "Работа ")
    }

    @Test func completionReturnsNilWhenNoMatchOrAlreadyComplete() {
        #expect(PaletteParser.completion(for: "Йо", knownCategories: work) == nil)
        #expect(PaletteParser.completion(for: "Работа", knownCategories: work) == nil)
        #expect(PaletteParser.completion(for: "", knownCategories: work) == nil)
    }
}
