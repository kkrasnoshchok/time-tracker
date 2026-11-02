import SwiftUI
import TimeTrackerCore

struct RunningTimerView: View {
    let model: AppModel
    let entry: TimeEntry
    @State private var notes: String

    init(model: AppModel, entry: TimeEntry) {
        self.model = model
        self.entry = entry
        _notes = State(initialValue: entry.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                CategoryDot(storedHex: entry.category?.colorHex ?? "")
                Text(entry.category?.name ?? "Без категории")
                    .font(.headline)
                Spacer()
                Text(DurationFormat.clock(model.elapsed))
                    .font(.system(.title3, design: .rounded).monospacedDigit())
            }
            if let title = entry.title {
                Text(title).font(.callout)
            }
            TextEditor(text: $notes)
                .font(.callout)
                .frame(height: 70)
                .overlay(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("Описание")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 5)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: notes) { _, newValue in
                    model.setNotes(newValue, for: entry)
                }
            Button("Остановить", action: model.stopTimer)
                .keyboardShortcut(.defaultAction)
        }
    }
}
