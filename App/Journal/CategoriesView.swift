import SwiftUI
import TimeTrackerCore

struct CategoriesView: View {
    let journal: JournalViewModel
    @State private var newName = ""
    @State private var problem: StoreError?
    @State private var deleting: EntryCategory?

    var body: some View {
        VStack(spacing: 12) {
            List {
                ForEach(journal.categories) { category in
                    CategoryRow(journal: journal, category: category, problem: $problem) {
                        requestDelete(category)
                    }
                }
                .onMove(perform: move)
            }
            HStack {
                TextField("Новая категория", text: $newName)
                    .onSubmit(add)
                Button("Добавить", action: add)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let problem {
                Text(problem.message).font(.callout).foregroundStyle(.red)
            }
        }
        .padding()
        .sheet(item: $deleting) { category in
            MoveEntriesSheet(journal: journal, category: category, problem: $problem)
        }
    }

    private func add() {
        do {
            try journal.addCategory(name: newName, colorHex: randomColor())
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

    private func randomColor() -> String {
        PaletteViewModel.categoryColors[journal.categories.count % PaletteViewModel.categoryColors.count]
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
        HStack {
            ColorPicker("", selection: colorBinding, supportsOpacity: false).labelsHidden()
            TextField("Название", text: $name)
                .onSubmit(rename)
            Spacer()
            Text("\(category.entries?.count ?? 0) записей").foregroundStyle(.secondary)
            Button("Удалить", systemImage: "trash", role: .destructive, action: onDelete)
                .labelStyle(.iconOnly)
        }
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: category.colorHex) },
            set: { newColor in
                do throws(StoreError) {
                    try journal.setColor(newColor.hexString, for: category)
                } catch {
                    problem = error
                }
            }
        )
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
        VStack(alignment: .leading, spacing: 12) {
            Text("В «\(category.name)» есть записи (\(category.entries?.count ?? 0)).").font(.headline)
            Text("Перенесите их в другую категорию, затем эта категория будет удалена.")
                .foregroundStyle(.secondary)
            Picker("Перенести в", selection: $destinationID) {
                ForEach(others) { Text($0.name).tag(UUID?.some($0.id)) }
            }
            HStack {
                Button("Отмена", role: .cancel) { dismiss() }
                Spacer()
                Button("Перенести и удалить", role: .destructive, action: moveAndDelete)
                    .disabled(destinationID == nil)
            }
        }
        .padding()
        .frame(width: 420)
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
