import SwiftUI
import TimeTrackerCore

struct JournalRootView: View {
    let model: AppModel
    @State private var journal: JournalViewModel

    init(model: AppModel) {
        self.model = model
        _journal = State(initialValue: JournalViewModel(store: model.store))
    }

    var body: some View {
        TabView {
            JournalEntriesView(journal: journal, model: model)
                .tabItem { Label("Записи", systemImage: "list.bullet") }
            CategoriesView(journal: journal)
                .tabItem { Label("Категории", systemImage: "tag") }
        }
        .frame(minWidth: 900, minHeight: 560)
    }
}
