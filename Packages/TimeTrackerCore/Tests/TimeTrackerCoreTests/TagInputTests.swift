import Testing
@testable import TimeTrackerCore

struct TagInputTests {
    @Test(arguments: [
        ("a b", ["a", "b"]),
        ("#a, #b", ["a", "b"]),
        ("#a;#b ,c", ["a", "b", "c"]),
        ("A a #A", ["A"]),
        ("  ##a  ", ["a"]),
        ("#", []),
        ("", []),
        ("   ", []),
        ("клиентX #созвон", ["клиентX", "созвон"]),
        ("#🔥", ["🔥"])
    ])
    func parse(text: String, expected: [String]) {
        #expect(TagInput.parse(text) == expected)
    }

    @Test func formatJoinsWithHashes() {
        #expect(TagInput.format(["a", "b"]) == "#a #b")
        #expect(TagInput.format([]) == "")
    }

    @Test func formatThenParseRoundTrips() {
        let tags = ["клиентx", "созвон", "🔥"]
        #expect(TagInput.parse(TagInput.format(tags)) == tags)
    }
}
