import SwiftUI
import TimeTrackerCore

/// Adds an entry for any past period, e.g. when the timer was forgotten.
/// A sheet is a modal layer over the window (like a React modal); `dismiss` from the
/// environment closes it, like an `onClose` prop.
struct AddEntrySheet: View {
    let journal: JournalViewModel
    let onAdded: (TimeEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntryDraft
    @State private var problem: StoreError?

    init(journal: JournalViewModel, now: Date, onAdded: @escaping (TimeEntry) -> Void) {
        self.journal = journal
        self.onAdded = onAdded
        _draft = State(initialValue: .blank(now: now, categoryID: journal.categories.first?.id))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x4) {
            Text("Новая запись").typeRole(.title).foregroundStyle(Color.textPrimary)
            ScrollView {
                EntryFormFields(draft: $draft, categories: journal.categories)
            }
            if let problem {
                ErrorStrip(
                    EntryProblem.message(problem),
                    action: EntryProblem.actionLabel(problem).map { label in
                        (label: label, handler: { add(allowOverlap: true) })
                    }
                )
            }
            HStack {
                Button("Отмена") { dismiss() }
                    .buttonStyle(.ghost)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Добавить") { add(allowOverlap: false) }
                    .buttonStyle(.primary)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Space.x5)
        .frame(width: 480, height: 600)
        .background(Color.surfaceCanvas)
    }

    private func add(allowOverlap: Bool) {
        do {
            let entry = try journal.save(draft, to: nil, allowOverlap: allowOverlap)
            onAdded(entry)
            dismiss()
        } catch {
            problem = error
        }
    }
}
