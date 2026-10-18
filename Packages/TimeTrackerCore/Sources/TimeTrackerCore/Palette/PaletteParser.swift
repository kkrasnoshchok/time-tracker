import Foundation

/// Parses palette input of the form `EntryCategory title words #tag #tag [-20m]`.
public enum PaletteParser {
    public static func parse(_ input: String, knownCategories: [String]) -> PaletteCommand? {
        var tags: [String] = []
        var words: [String] = []
        for token in input.split(whereSeparator: \.isWhitespace).map(String.init) {
            if token.hasPrefix("#"), token.count > 1 {
                let tag = String(token.dropFirst()).lowercased()
                if !tags.contains(tag) { tags.append(tag) }
            } else {
                words.append(token)
            }
        }

        var offset: TimeInterval = 0
        if let last = words.last, let seconds = offsetSeconds(last) {
            offset = seconds
            words.removeLast()
        }

        guard let firstWord = words.first else { return nil }

        let category: PaletteCommand.CategoryRef
        let consumed: Int
        if let match = longestMatch(in: words, among: knownCategories) {
            category = .existing(match.name)
            consumed = match.wordCount
        } else {
            category = .unknown(firstWord)
            consumed = 1
        }

        let title = words.dropFirst(consumed).joined(separator: " ")
        return PaletteCommand(
            category: category,
            title: title.isEmpty ? nil : title,
            tags: tags,
            startOffset: offset
        )
    }

    /// Text to put in the field when the user presses Tab, or nil if nothing completes.
    public static func completion(for input: String, knownCategories: [String]) -> String? {
        let typed = String(input.drop(while: \.isWhitespace)).lowercased()
        guard !typed.isEmpty, !typed.contains("#") else { return nil }
        for name in knownCategories {
            let lowered = name.lowercased()
            if lowered.hasPrefix(typed), lowered != typed { return name + " " }
        }
        return nil
    }

    private static func offsetSeconds(_ token: String) -> TimeInterval? {
        guard token.hasPrefix("-"), let unit = token.last, unit == "m" || unit == "h" else { return nil }
        guard let amount = Int(token.dropFirst().dropLast()), amount >= 0 else { return nil }
        return TimeInterval(amount) * (unit == "h" ? 3600 : 60)
    }

    private static func longestMatch(
        in words: [String],
        among categories: [String]
    ) -> (name: String, wordCount: Int)? {
        var best: (name: String, wordCount: Int)?
        for name in categories {
            let nameWords = name.split(whereSeparator: \.isWhitespace).map { $0.lowercased() }
            guard !nameWords.isEmpty, words.count >= nameWords.count else { continue }
            let typed = words.prefix(nameWords.count).map { $0.lowercased() }
            if typed == nameWords, nameWords.count > (best?.wordCount ?? 0) {
                best = (name, nameWords.count)
            }
        }
        return best
    }
}
