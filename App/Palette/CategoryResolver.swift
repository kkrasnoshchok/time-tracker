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

    /// Invisible character the field shows in front of the text while a token is displayed.
    /// The text field swallows Backspace at the start of an empty or untouched field, so the
    /// key press gives no signal; deleting this character is the signal instead.
    static let anchor = "\u{200B}"

    /// What the text field shows: the anchor plus the text after the token.
    static func fieldText(for split: Split) -> String {
        anchor + split.rest
    }

    /// The new `viewModel.input` after the field's text changed while a token is shown.
    /// Deleting only the anchor (Backspace at the start) dissolves the token; any other edit keeps it.
    static func input(afterEditing text: String, split: Split) -> String {
        if !text.contains(anchor), text == split.rest { return split.inputAfterBackspace }
        return split.prefix + text.replacingOccurrences(of: anchor, with: "")
    }

    /// Where the caret goes (in characters from the start of the new line) after Backspace removed the
    /// separator: right after the name as typed. `nil` when the line still resolves to a token
    /// (several spaces after the name), because the field text then differs from the line.
    static func caretOffsetAfterDissolve(_ split: Split, among names: [String]) -> Int? {
        guard Self.split(split.inputAfterBackspace, among: names) == nil else { return nil }
        return split.prefix.dropLast().count
    }
}
