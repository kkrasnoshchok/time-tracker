import SwiftUI
import TimeTrackerCore

struct PaletteView: View {
    @Bindable var viewModel: PaletteViewModel
    let model: AppModel
    let onClose: () -> Void
    @FocusState private var focused: Bool
    /// Caret/selection inside the text field, like a ref to the input's `selectionStart`.
    @State private var textSelection: TextSelection?
    /// Row highlighted by ↑/↓; reset whenever the rows change.
    @State private var selection = PaletteSelection()

    private static let inputHint = "Категория название #тег -20m"

    var body: some View {
        VStack(spacing: 0) {
            inputRow
            if let entry = model.running {
                runningRow(entry)
            }
            if !viewModel.items.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                        itemRow(item, isSelected: index == selection.index)
                    }
                }
                .padding(Space.x2)
            }
            if let prompt = viewModel.prompt {
                promptRow(prompt)
            }
        }
        .frame(width: 640)
        // The panel is always light paper, so unstyled text must not follow a dark system theme.
        .foregroundStyle(Color.textPrimary)
        .background(Color.surfaceCard, in: panelShape)
        .clipShape(panelShape)
        .hairlineRing(panelShape, variant: .palette)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            focused = true
        }
        .onAppear { focused = true }
        .onChange(of: viewModel.items) { selection.reset() }
    }

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
    }

    /// Category the line starts with, if any. Recomputed on each render from the live store.
    private var categorySplit: CategoryResolver.Split? {
        CategoryResolver.split(viewModel.input, among: categoryNames)
    }

    private var inputRow: some View {
        let split = categorySplit
        return HStack(spacing: Space.x3) {
            Image(systemName: "magnifyingglass")
                .typeRole(.paletteInput)
                .fontWeight(.light)
                .foregroundStyle(Color.textTertiary)
                .accessibilityHidden(true)
            if let split {
                CategoryToken(name: split.name, storedHex: hex(forCategory: split.name))
                    .accessibilityLabel("Категория \(split.name)")
            }
            inputField(split: split)
        }
        .padding(.horizontal, Space.x4)
        .frame(height: Space.paletteFieldHeight)
    }

    /// The field edits only the text after the token; `viewModel.input` stays `prefix + rest`.
    /// Like a controlled `<input value={rest} onChange={e => setInput(prefix + e.target.value)}>`.
    private func inputField(split: CategoryResolver.Split?) -> some View {
        let text = Binding(
            get: { split.map(CategoryResolver.fieldText(for:)) ?? viewModel.input },
            set: { newText in
                guard let split else { viewModel.input = newText; return }
                let input = CategoryResolver.input(afterEditing: newText, split: split)
                let dissolved = input == split.inputAfterBackspace
                viewModel.input = input
                if dissolved, let offset = CategoryResolver.caretOffsetAfterDissolve(split, among: categoryNames) {
                    textSelection = TextSelection(insertionPoint: input.index(input.startIndex, offsetBy: offset))
                }
            }
        )
        return ZStack(alignment: .leading) {
            Text(Self.mutingTags(in: text.wrappedValue))
                .typeRole(.paletteInput)
                .lineLimit(1)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            TextField(
                "",
                text: text,
                selection: $textSelection,
                prompt: Text(Self.inputHint).foregroundStyle(Color.textTertiary)
            )
                .textFieldStyle(.plain)
                .typeRole(.paletteInput)
                // The text is drawn by the layer behind (to mute #tags); the field keeps caret and editing.
                .foregroundStyle(Color.clear)
                .accessibilityLabel(Self.inputHint)
                .focused($focused)
                .onSubmit { submit() }
                .onKeyPress(.downArrow) {
                    selection.moveDown(count: viewModel.items.count)
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    selection.moveUp(count: viewModel.items.count)
                    return .handled
                }
                .onKeyPress(.tab) {
                    tab()
                    return .handled
                }
                .onKeyPress(.escape) {
                    if !viewModel.cancelPrompt() { onClose() }
                    return .handled
                }
        }
    }

    private var categoryNames: [String] {
        model.store.categories().map(\.name)
    }

    private func hex(forCategory name: String) -> String {
        model.store.categories().first { $0.name == name }?.colorHex ?? ""
    }

    /// The typed text with `#tag` words in the secondary color. The invisible token anchor has no
    /// width, so it is left out of the drawn layer: it would hide a `#` that follows it.
    static func mutingTags(in text: String) -> AttributedString {
        var result = AttributedString(text.replacingOccurrences(of: CategoryResolver.anchor, with: ""))
        result.foregroundColor = Color.textPrimary
        var index = result.startIndex
        while index < result.endIndex {
            let wordEnd = result[index...].characters.firstIndex(where: \.isWhitespace) ?? result.endIndex
            if result.characters[index] == "#", result.characters.distance(from: index, to: wordEnd) > 1 {
                result[index..<wordEnd].foregroundColor = Color.textTertiary
            }
            index = wordEnd == result.endIndex ? wordEnd : result.characters.index(after: wordEnd)
        }
        return result
    }

    private func runningRow(_ entry: TimeEntry) -> some View {
        HStack(spacing: Space.x3) {
            Text(entry.title ?? entry.category?.name ?? "")
                .typeRole(.body)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            Spacer(minLength: Space.x2)
            HStack(spacing: Space.x2) {
                CategoryDot(storedHex: entry.category?.colorHex ?? "")
                // Without a title the category name is already the main text on the left.
                if entry.title != nil {
                    Text(entry.category?.name ?? "")
                        .lineLimit(1)
                }
            }
            Text(DurationFormat.clock(model.elapsed)).monospacedDigit()
        }
        .typeRole(.micro)
        .foregroundStyle(Color.textSecondary)
        .padding(.horizontal, Space.x4)
        .padding(.vertical, Space.x2)
        .frame(maxWidth: .infinity)
        .background(Color.surfaceCanvas)
        .accessibilityElement(children: .combine)
    }

    private func itemRow(_ item: PaletteItem, isSelected: Bool) -> some View {
        let (text, hint) = Self.rowContent(for: item)
        return HStack(spacing: Space.x3) {
            Text(text)
                .typeRole(.body)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            Spacer(minLength: Space.x2)
            Text(hint)
                .typeRole(.micro)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, Space.x3)
        .frame(height: Space.suggestionRowHeight)
        .background(
            isSelected ? Color.surfaceInset : Color.clear,
            in: RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
        )
        .contentShape(Rectangle())
        .onTapGesture { activate(item) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(Self.isSuggestion(item) ? .isButton : [])
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private static func rowContent(for item: PaletteItem) -> (text: String, hint: String) {
        switch item {
        case .stopCurrent:
            ("Остановить текущую запись", "⏎")
        case .repeatLast(let title, let category):
            ("Повторить: " + [category, title].compactMap { $0 }.joined(separator: " — "), "⏎")
        case .createCategory(let name):
            ("Создать категорию «\(name)»", "⏎")
        case .suggestion(let text):
            (text, "⇥")
        }
    }

    private static func isSuggestion(_ item: PaletteItem) -> Bool {
        if case .suggestion = item { return true }
        return false
    }

    /// Click on a row, or Enter on the selected one. Only suggestions react: they fill the field.
    private func activate(_ item: PaletteItem) {
        if case .suggestion(let text) = item { viewModel.input = text }
    }

    private func promptRow(_ prompt: PalettePrompt) -> some View {
        let text: String
        switch prompt {
        case .createCategory(let name):
            text = "Категории «\(name)» нет. ⏎ — создать и запустить, Esc — отмена."
        case .overlap(let count):
            text = "Пересекается с записями: \(count). ⏎ — всё равно, Esc — править."
        case .error(let message):
            text = message
        }
        return ErrorStrip(text)
            .padding(.horizontal, Space.x2)
            .padding(.vertical, Space.x2)
    }

    /// Tab: a selected suggestion fills the field; otherwise complete the category or take the first suggestion.
    private func tab() {
        if let text = selection.fillText(in: viewModel.items) {
            viewModel.input = text
        } else {
            viewModel.tab()
        }
    }

    /// Enter: a selected suggestion fills the field; anything else submits as before.
    private func submit() {
        if let text = selection.fillText(in: viewModel.items) {
            viewModel.input = text
            return
        }
        handle(viewModel.enter())
    }

    private func handle(_ outcome: PaletteOutcome) {
        model.refresh()
        switch outcome {
        case .started, .stopped: onClose()
        default: break
        }
    }
}
