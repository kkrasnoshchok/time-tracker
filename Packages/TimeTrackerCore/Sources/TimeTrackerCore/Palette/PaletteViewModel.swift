import Foundation
import Observation

public enum PaletteItem: Equatable, Sendable {
    case stopCurrent
    case repeatLast(title: String?, category: String)
    case createCategory(String)
    /// Full replacement text for the input field.
    case suggestion(String)
}

public enum PaletteOutcome: Equatable {
    case started
    case stopped
    case needsCategoryCreation(String)
    case overlap([UUID])
    case failed(StoreError)
    case nothing
}

/// State and actions behind the palette window. The view only renders `items` and forwards keys.
@MainActor
@Observable
public final class PaletteViewModel {
    public var input: String = "" {
        didSet { reload() }
    }
    public private(set) var items: [PaletteItem] = []

    private let store: TimeStore

    public init(store: TimeStore) {
        self.store = store
        reload()
    }

    /// Recomputes `items`; call when the store changed outside the palette (e.g. timer stopped in the menu bar).
    public func reload() {
        items = computeItems()
    }

    /// Tab: complete the category name, otherwise take the first suggestion.
    public func tab() {
        let names = store.categories().map(\.name)
        if let completed = PaletteParser.completion(for: input, knownCategories: names) {
            input = completed
            return
        }
        for case .suggestion(let text) in items {
            input = text
            return
        }
    }

    @discardableResult
    public func submit(allowOverlap: Bool = false) -> PaletteOutcome {
        defer { reload() }
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return submitEmptyInput(allowOverlap: allowOverlap)
        }
        guard let command = parsedCommand() else { return .nothing }
        switch command.category {
        case .unknown(let word):
            return .needsCategoryCreation(word)
        case .existing(let name):
            guard let category = store.categories().first(where: { $0.name == name }) else { return .nothing }
            return start(category, command, allowOverlap: allowOverlap)
        }
    }

    @discardableResult
    public func createCategoryAndSubmit(colorHex: String) -> PaletteOutcome {
        guard let command = parsedCommand() else { return .nothing }
        if case .unknown(let word) = command.category {
            do {
                try store.addCategory(name: word, colorHex: colorHex)
            } catch {
                return .failed(error)
            }
        }
        return submit()
    }

    // MARK: Private

    private func parsedCommand() -> PaletteCommand? {
        PaletteParser.parse(input, knownCategories: store.categories().map(\.name))
    }

    private func submitEmptyInput(allowOverlap: Bool) -> PaletteOutcome {
        if store.runningEntry() != nil {
            do {
                try store.stopTimer()
                return .stopped
            } catch {
                return .failed(error)
            }
        }
        guard let last = store.lastEntry(), let category = last.category else { return .nothing }
        let command = PaletteCommand(
            category: .existing(category.name), title: last.title, tags: last.tagList.map(\.name)
        )
        return start(category, command, allowOverlap: allowOverlap)
    }

    private func start(_ category: EntryCategory, _ command: PaletteCommand, allowOverlap: Bool) -> PaletteOutcome {
        let startedAt = command.startOffset > 0 ? store.time.now().addingTimeInterval(-command.startOffset) : nil
        do {
            try store.startTimer(
                category: category, title: command.title, tags: command.tags,
                startedAt: startedAt, allowOverlap: allowOverlap
            )
            input = ""
            return .started
        } catch {
            if case .overlap(let ids) = error { return .overlap(ids) }
            return .failed(error)
        }
    }

    private func computeItems() -> [PaletteItem] {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if store.runningEntry() != nil { return [.stopCurrent] }
            guard let last = store.lastEntry() else { return [] }
            return [.repeatLast(title: last.title, category: last.category?.name ?? "")]
        }
        let names = store.categories().map(\.name)
        guard let command = PaletteParser.parse(input, knownCategories: names) else { return [] }

        switch command.category {
        case .unknown(let word):
            var items: [PaletteItem] = []
            if trimmed.split(whereSeparator: \.isWhitespace).count == 1 {
                let matching = names.filter { $0.lowercased().hasPrefix(word.lowercased()) }
                items += matching.map { .suggestion($0 + " ") }
            }
            return items + [.createCategory(word)]
        case .existing(let name):
            guard command.tags.isEmpty, command.startOffset == 0 else { return [] }
            let typed = command.title ?? ""
            let titles = store.recentTitles(limit: 50)
                .filter { $0.lowercased().hasPrefix(typed.lowercased()) && $0 != typed }
                .prefix(5)
            return titles.map { .suggestion("\(name) \($0)") }
        }
    }
}
