import Foundation

/// Converts between the text a person types for tags (`#a #b`, `a, b`) and a list of tag names.
public enum TagInput {
    /// Splits on spaces, commas and semicolons, strips leading `#`, drops duplicates (ignoring case).
    public static func parse(_ text: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        let separators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",;"))
        for piece in text.components(separatedBy: separators) {
            let name = String(piece.drop(while: { $0 == "#" }))
            guard !name.isEmpty, seen.insert(name.lowercased()).inserted else { continue }
            result.append(name)
        }
        return result
    }

    public static func format(_ tags: [String]) -> String {
        tags.map { "#" + $0 }.joined(separator: " ")
    }
}
