import Foundation
import Testing
@testable import TimeTrackerCore

@MainActor
struct CSVExporterTests {
    private func row(
        start: Date = at(9),
        end: Date? = at(10, 30),
        duration: Int = 5400,
        category: String = "Работа",
        tags: [String] = [],
        title: String = "",
        notes: String = ""
    ) -> ExportRow {
        ExportRow(
            start: start, end: end, durationSeconds: duration,
            category: category, tags: tags, title: title, notes: notes
        )
    }

    private func fields(of exported: String) -> [String] {
        parseCSV(exported)[1]
    }

    @Test func headerMatchesSpecColumns() {
        #expect(CSVExporter.header == "start,end,duration_seconds,category,tags,title,notes")
        #expect(CSVExporter.csv([]) == "start,end,duration_seconds,category,tags,title,notes\r\n")
    }

    @Test func writesOneLinePerRowWithIsoUtcDates() {
        let line = CSVExporter.csv([row(tags: ["a", "b"], title: "созвон", notes: "описание")])
        #expect(line == CSVExporter.header + "\r\n"
            + "2027-01-15T09:00:00Z,2027-01-15T10:30:00Z,5400,Работа,a;b,созвон,описание\r\n")
    }

    @Test func quotesFieldsWithCommasQuotesAndNewlines() {
        let title = "He said \"hi\", ok\nbye"
        let csv = CSVExporter.csv([row(title: title)])
        #expect(csv.contains("\"He said \"\"hi\"\", ok\nbye\""))
        #expect(fields(of: csv)[5] == title)
    }

    @Test(arguments: ["строка1\nстрока2", "строка1\rстрока2", "строка1\r\nстрока2"])
    func fieldWithOnlyLineBreakIsQuoted(value: String) {
        let csv = CSVExporter.csv([row(notes: value)])
        #expect(csv.contains("\"" + value + "\""))
        #expect(fields(of: csv)[6] == value)
        #expect(parseCSV(csv).count == 2)
    }

    @Test(arguments: ["=SUM(A1)", "+1", "-1", "@cmd", "\t=1", "\r=1"])
    func neutralizesFormulaPrefix(value: String) {
        let csv = CSVExporter.csv([row(category: value, title: value, notes: value)])
        let parsed = fields(of: csv)
        #expect(parsed[3] == "'" + value)
        #expect(parsed[5] == "'" + value)
        #expect(parsed[6] == "'" + value)
    }

    @Test func neutralizedFieldWithCommaIsStillQuoted() {
        let csv = CSVExporter.csv([row(title: "=1,2")])
        #expect(fields(of: csv)[5] == "'=1,2")
        #expect(fields(of: csv).count == 7)
    }

    @Test func harmlessDashInsideTextIsNotChanged() {
        let csv = CSVExporter.csv([row(title: "созвон - итоги", notes: "a=b")])
        #expect(fields(of: csv)[5] == "созвон - итоги")
        #expect(fields(of: csv)[6] == "a=b")
    }

    @Test func runningEntryHasEmptyEnd() {
        let csv = CSVExporter.csv([row(end: nil, duration: 1800)])
        #expect(fields(of: csv)[1].isEmpty)
        #expect(fields(of: csv)[2] == "1800")
    }

    @Test func emptyNotesAndTagsAreEmptyFields() {
        let parsed = fields(of: CSVExporter.csv([row()]))
        #expect(parsed.count == 7)
        #expect(parsed[4].isEmpty && parsed[5].isEmpty && parsed[6].isEmpty)
    }

    @Test func unicodeSurvivesRoundTrip() {
        let title = "Спорт 🏃‍♂️ бег — 5 км"
        #expect(fields(of: CSVExporter.csv([row(title: title)]))[5] == title)
    }

    @Test func manyRowsRoundTripThroughParser() {
        let rows = (0..<50).map { index in
            row(category: "К\(index)", title: "t,\(index)\n\"x\"", notes: "n\(index)")
        }
        let parsed = parseCSV(CSVExporter.csv(rows))
        #expect(parsed.count == 51)
        #expect(parsed[50][5] == "t,49\n\"x\"")
    }

    // MARK: ExportRow from a stored entry

    @Test func exportRowIsBuiltFromEntryWithSortedTagsAndRunningDuration() throws {
        let time = TestTimeProvider(at(9))
        let store = try TimeStore.inMemory(time: time)
        let work = try store.addCategory(name: "Работа", colorHex: "#0A84FF")
        let running = try store.startTimer(category: work, title: nil, tags: ["б", "а"])
        let row = ExportRow(entry: running, now: at(10, 15))
        #expect(row.end == nil)
        #expect(row.durationSeconds == 4500)
        #expect(row.category == "Работа")
        #expect(row.tags == ["а", "б"])
        #expect(row.title.isEmpty && row.notes.isEmpty)
    }
}
