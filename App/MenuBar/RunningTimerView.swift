import SwiftUI
import TimeTrackerCore

struct RunningTimerView: View {
    let model: AppModel
    let entry: TimeEntry
    // `@State` with an initial value from props, like `useState(props.notes)`:
    // the initializer runs once, later prop changes do not reset it.
    @State private var notes: String
    @FocusState private var notesFocused: Bool

    init(model: AppModel, entry: TimeEntry) {
        self.model = model
        self.entry = entry
        _notes = State(initialValue: entry.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x3) {
            HStack(spacing: Space.x2) {
                CategoryDot(storedHex: entry.category?.colorHex ?? "")
                Text(PopoverText.categoryName(entry.category?.name))
                    .typeRole(.bodyEmphasis)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
            }
            Text(DurationFormat.clock(model.elapsed))
                .typeRole(.timerDisplay)
                .foregroundStyle(Color.textPrimary)
                .tabularFigures()
                .lineLimit(1)
            if let title = entry.title {
                Text(title)
                    .typeRole(.body)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
            }
            notesEditor
            Button("Остановить", action: model.stopTimer)
                .buttonStyle(.primary)
                .keyboardShortcut(.defaultAction)
        }
    }

    /// Notes use the input field look (`InputFieldShell`) around a multiline `TextEditor`.
    /// `onChange` runs a side effect when `notes` changes, like `useEffect(..., [notes])`.
    private var notesEditor: some View {
        InputFieldShell(
            isFocused: notesFocused,
            content: TextEditor(text: $notes)
                .scrollContentBackground(.hidden)
                .focused($notesFocused)
                .frame(minHeight: 70, maxHeight: 70)
                .onChange(of: notes) { _, newValue in
                    model.setNotes(newValue, for: entry)
                }
        )
        .overlay(alignment: .topLeading) {
            if notes.isEmpty {
                Text("Описание")
                    .typeRole(.body)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.horizontal, Space.x3 + 5)
                    .padding(.top, Space.x2)
                    .allowsHitTesting(false)
            }
        }
    }
}
