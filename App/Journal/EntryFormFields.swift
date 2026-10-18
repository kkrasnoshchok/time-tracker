import SwiftUI
import TimeTrackerCore

/// The editable fields of an entry, shared by the detail panel and the "add entry" sheet.
struct EntryFormFields: View {
    @Binding var draft: EntryDraft
    let categories: [EntryCategory]

    var body: some View {
        Form {
            Picker("Категория", selection: $draft.categoryID) {
                ForEach(categories) { Text($0.name).tag(UUID?.some($0.id)) }
            }
            TextField("Название", text: $draft.title)
            TextField("Теги", text: $draft.tags, prompt: Text("#тег #тег"))
            DatePicker("Начало", selection: $draft.start)
            if let end = draft.end {
                DatePicker("Конец", selection: Binding(get: { end }, set: { draft.end = $0 }))
            } else {
                LabeledContent("Конец") { Text("таймер идёт").foregroundStyle(.secondary) }
            }
            Section("Описание") {
                TextEditor(text: $draft.notes)
                    .font(.body)
                    .frame(minHeight: 140)
            }
        }
        .formStyle(.grouped)
    }
}

/// Shows a `StoreError`; an overlap offers a "save anyway" button.
struct ProblemBanner: View {
    let problem: StoreError
    let onSaveAnyway: () -> Void

    var body: some View {
        HStack {
            Text(problem.message).foregroundStyle(.red)
            Spacer()
            if case .overlap = problem {
                Button("Всё равно", action: onSaveAnyway)
            }
        }
        .font(.callout)
    }
}
