import SwiftUI
import TimeTrackerCore

/// The editable fields of an entry, shared by the detail panel and the "add entry" sheet.
///
/// Instead of the system `Form` (a grouped list the app cannot restyle), the fields are
/// plain stacks inside `card()`s, like `<div className="card">` blocks in React. The
/// parent owns `draft`; `$draft` is a two-way `Binding`, i.e. `value` + `onChange` in one.
struct EntryFormFields: View {
    @Binding var draft: EntryDraft
    let categories: [EntryCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x4) {
            card {
                field("Категория") {
                    Picker("Категория", selection: $draft.categoryID) {
                        ForEach(categories) { Text($0.name).tag(UUID?.some($0.id)) }
                    }
                    .labelsHidden()
                }
                field("Название") { InputField("Название", text: $draft.title) }
                field("Теги") { InputField("#тег #тег", text: $draft.tags) }
            }
            card {
                field("Начало") {
                    DatePicker("Начало", selection: $draft.start).labelsHidden()
                }
                field("Конец") { endField }
            }
            card {
                field("Описание") { notesEditor }
            }
        }
    }

    @ViewBuilder private var endField: some View {
        if let end = draft.end {
            DatePicker("Конец", selection: Binding(get: { end }, set: { draft.end = $0 }))
                .labelsHidden()
        } else {
            Text("таймер идёт")
                .typeRole(.body)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var notesEditor: some View {
        InputFieldShell(
            isFocused: false,
            content: TextEditor(text: $draft.notes)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .accessibilityLabel("Описание")
        )
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Space.x3) { content() }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
    }

    private func field<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Space.x1) {
            Text(label).typeRole(.caption).foregroundStyle(Color.textSecondary)
            content()
        }
    }
}
