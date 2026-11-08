import SwiftUI
import TimeTrackerCore

struct CategoriesView: View {
    let journal: JournalViewModel
    @State private var newName = ""
    @State private var problem: StoreError?
    @State private var deleting: EntryCategory?

    var body: some View {
        VStack(spacing: Space.x4) {
            // `List` stays: it gives drag-to-reorder (`onMove`). Its own background and
            // separators are hidden, and the card around it supplies the paper look.
            List {
                ForEach(journal.categories) { category in
                    CategoryRow(journal: journal, category: category, problem: $problem) {
                        requestDelete(category)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onMove(perform: move)
            }
            .scrollContentBackground(.hidden)
            .card()
            HStack(spacing: Space.x3) {
                InputField("Новая категория", text: $newName)
                    .onSubmit(add)
                Button("Добавить", action: add)
                    .buttonStyle(.primary)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let problem {
                ErrorStrip(EntryProblem.message(problem))
            }
        }
        .padding(Space.x5)
        .background(Color.surfaceCanvas)
        .sheet(item: $deleting) { category in
            MoveEntriesSheet(journal: journal, category: category, problem: $problem)
        }
    }

    private func add() {
        do {
            try journal.addCategory(name: newName, colorHex: newCategoryHex())
            newName = ""
            problem = nil
        } catch {
            problem = error
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = journal.categories
        ordered.move(fromOffsets: source, toOffset: destination)
        do {
            try journal.reorderCategories(ordered)
            problem = nil
        } catch {
            problem = error
        }
    }

    private func requestDelete(_ category: EntryCategory) {
        if (category.entries ?? []).isEmpty {
            do {
                try journal.deleteCategory(category, movingEntriesTo: nil)
                problem = nil
            } catch {
                problem = error
            }
        } else {
            deleting = category
        }
    }

    /// First tone no category uses yet; its own hex is stored so it maps to itself.
    private func newCategoryHex() -> String {
        CategoryTone.nextFree(usedStoredHexes: journal.categories.map(\.colorHex)).hex
    }
}

private struct CategoryRow: View {
    let journal: JournalViewModel
    let category: EntryCategory
    @Binding var problem: StoreError?
    let onDelete: () -> Void
    @State private var name: String

    init(
        journal: JournalViewModel,
        category: EntryCategory,
        problem: Binding<StoreError?>,
        onDelete: @escaping () -> Void
    ) {
        self.journal = journal
        self.category = category
        _problem = problem
        self.onDelete = onDelete
        _name = State(initialValue: category.name)
    }

    var body: some View {
        HStack(spacing: Space.x3) {
            ToneSwatchPicker(storedHex: category.colorHex, onSelect: select)
            InputField("Название", text: $name)
                .onSubmit(rename)
            Text("\(category.entries?.count ?? 0) записей")
                .typeRole(.caption)
                .foregroundStyle(Color.textSecondary)
            Button("Удалить", systemImage: "trash", role: .destructive, action: onDelete)
                .labelStyle(.iconOnly)
                .buttonStyle(.ghost)
        }
    }

    private func select(_ tone: CategoryTone) {
        do throws(StoreError) {
            try journal.setColor(tone.hex, for: category)
            problem = nil
        } catch {
            problem = error
        }
    }

    private func rename() {
        do {
            try journal.renameCategory(category, to: name)
            problem = nil
        } catch {
            problem = error
            name = category.name
        }
    }
}

/// A category with entries cannot be deleted until its entries move somewhere else.
private struct MoveEntriesSheet: View {
    let journal: JournalViewModel
    let category: EntryCategory
    @Binding var problem: StoreError?
    @Environment(\.dismiss) private var dismiss
    @State private var destinationID: UUID?

    private var others: [EntryCategory] { journal.categories.filter { $0.id != category.id } }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x4) {
            Text("В «\(category.name)» есть записи (\(category.entries?.count ?? 0)).")
                .typeRole(.bodyEmphasis)
                .foregroundStyle(Color.textPrimary)
            Text("Перенесите их в другую категорию, затем эта категория будет удалена.")
                .typeRole(.body)
                .foregroundStyle(Color.textSecondary)
            // Native menu `Picker`, like in the entry form (design session owns restyling it).
            Picker("Перенести в", selection: $destinationID) {
                ForEach(others) { Text($0.name).tag(UUID?.some($0.id)) }
            }
            .typeRole(.body)
            HStack {
                Button("Отмена", role: .cancel) { dismiss() }
                    .buttonStyle(.ghost)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Перенести и удалить", role: .destructive, action: moveAndDelete)
                    .buttonStyle(.primary)
                    .keyboardShortcut(.defaultAction)
                    .disabled(destinationID == nil)
            }
        }
        .padding(Space.x5)
        .frame(width: 420)
        .background(Color.surfaceCanvas)
        .onAppear { destinationID = others.first?.id }
    }

    private func moveAndDelete() {
        guard let destination = others.first(where: { $0.id == destinationID }) else { return }
        do {
            try journal.deleteCategory(category, movingEntriesTo: destination)
            problem = nil
        } catch {
            problem = error
        }
        dismiss()
    }
}
