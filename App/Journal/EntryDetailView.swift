import SwiftUI
import TimeTrackerCore

/// Edits one entry. Every change is saved at once; a failed save keeps the form and shows why.
struct EntryDetailView: View {
    let journal: JournalViewModel
    let entry: TimeEntry
    let onDelete: () -> Void
    @State private var draft: EntryDraft
    @State private var problem: StoreError?
    @State private var confirmingDelete = false

    init(journal: JournalViewModel, entry: TimeEntry, onDelete: @escaping () -> Void) {
        self.journal = journal
        self.entry = entry
        self.onDelete = onDelete
        _draft = State(initialValue: EntryDraft(entry: entry))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x4) {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.x4) {
                    EntryFormFields(draft: $draft, categories: journal.categories)
                    HStack {
                        Spacer()
                        Button("Удалить запись", role: .destructive) { confirmingDelete = true }
                            .buttonStyle(.ghost)
                    }
                }
            }
            // Outside the scroll area, so a failed autosave stays in view.
            if let problem {
                ErrorStrip(
                    EntryProblem.message(problem),
                    action: EntryProblem.actionLabel(problem).map { label in
                        (label: label, handler: { save(allowOverlap: true) })
                    }
                )
            }
        }
        .padding(Space.x5)
        .background(Color.surfaceCanvas)
        .onChange(of: draft) { save(allowOverlap: false) }
        .confirmationDialog("Удалить запись?", isPresented: $confirmingDelete) {
            Button("Удалить", role: .destructive, action: delete)
        }
    }

    private func save(allowOverlap: Bool) {
        do {
            try journal.save(draft, to: entry, allowOverlap: allowOverlap)
            problem = nil
        } catch {
            problem = error
        }
    }

    private func delete() {
        do {
            try journal.delete(entry)
            onDelete()
        } catch {
            problem = error
        }
    }
}
