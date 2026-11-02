import Foundation

/// Splits the palette line into a typed category prefix and the remaining text.
/// Pure and UI-free, like a `splitCategory(line, names)` helper you would unit-test in TS.
enum CategoryResolver {
    struct Split: Equatable {
        /// Canonical category name from the store.
        let name: String
        /// Text exactly as typed, up to and including the separating whitespace.
        let prefix: String
        let rest: String

        /// The line after Backspace at the start of `rest`: the separator is deleted,
        /// so the name merges back into the text and no longer resolves.
        var inputAfterBackspace: String {
            String(prefix.dropLast()) + rest
        }
    }

    /// The longest category name the line starts with (case-insensitive), followed by whitespace.
    static func split(_ input: String, among names: [String]) -> Split? {
        var best: (name: String, end: String.Index)?
        for name in names where !name.isEmpty {
            guard let range = input.range(of: name, options: [.caseInsensitive, .anchored]),
                  range.upperBound < input.endIndex,
                  input[range.upperBound].isWhitespace else { continue }
            if best == nil || name.count > best!.name.count { best = (name, range.upperBound) }
        }
        guard let best else { return nil }
        let restStart = input.index(after: best.end)
        return Split(name: best.name, prefix: String(input[..<restStart]), rest: String(input[restStart...]))
    }
}
