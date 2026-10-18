import SwiftUI
import TimeTrackerCore

/// Adds an entry for any past period, e.g. when the timer was forgotten.
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
        VStack(spacing: 8) {
            Text("Новая запись").font(.headline).padding(.top)
            EntryFormFields(draft: $draft, categories: journal.categories)
            if let problem {
                ProblemBanner(problem: problem) { add(allowOverlap: true) }
                    .padding(.horizontal)
            }
            HStack {
                Button("Отмена", role: .cancel) { dismiss() }
                Spacer()
                Button("Добавить") { add(allowOverlap: false) }
                    .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom])
        }
        .frame(width: 480, height: 540)
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
