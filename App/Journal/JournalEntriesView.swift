import SwiftUI
import TimeTrackerCore

struct JournalEntriesView: View {
    @Bindable var journal: JournalViewModel
    let model: AppModel
    @State private var selection: UUID?
    @State private var period: Period = .all
    @State private var showingAddSheet = false
    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    enum Period: String, CaseIterable, Identifiable {
        case all = "Всё время"
        case today = "Сегодня"
        case week = "7 дней"
        case month = "30 дней"

        var id: String { rawValue }

        var days: Int? {
            switch self {
            case .all: nil
            case .today: 0
            case .week: 6
            case .month: 29
            }
        }
    }

    private static let detailWidth: CGFloat = 400

    private var selectedEntry: TimeEntry? {
        journal.groups.flatMap(\.entries).first { $0.id == selection }
    }

    var body: some View {
        // Fixed-width detail pane: the list takes the rest, so its width depends
        // only on the window, never on what the detail pane contains.
        HStack(spacing: 0) {
            entryList.frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            detail.frame(width: Self.detailWidth).frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .searchable(text: $journal.filter.text, prompt: "Поиск по названию, описанию, тегам")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingAddSheet) {
            AddEntrySheet(journal: journal, now: model.now) { selection = $0.id }
        }
        .onChange(of: period) { applyPeriod() }
        .onChange(of: model.running?.id) { journal.reload() }
        .onReceive(refreshTimer) { _ in journal.reload() }
        .onAppear { journal.reload() }
    }

    /// Selection is drawn and handled by us, not by `List(selection:)`: the native
    /// macOS highlight is the system blue and cannot be restyled. A tap sets
    /// `selection`, the arrow keys move it, and each row paints its own state
    /// (like a controlled component in React instead of a native <select>).
    private var entryList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(journal.groups, id: \.day) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            EntryRow(entry: entry, now: model.now, isSelected: selection == entry.id)
                                .id(entry.id)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onTapGesture { selection = entry.id }
                        }
                    } header: {
                        DayHeader(group: group, now: model.now)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .focusable()
            .focusEffectDisabled()
            .onKeyPress(.upArrow) { moveSelection(by: -1, proxy: proxy) }
            .onKeyPress(.downArrow) { moveSelection(by: 1, proxy: proxy) }
            .overlay {
                if journal.groups.isEmpty {
                    Text(journal.filter == EntryFilter() ? "Записей пока нет." : "Ничего не найдено.")
                        .typeRole(.body)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let entry = selectedEntry {
            EntryDetailView(journal: journal, entry: entry) { selection = nil }
                .id(entry.id)
        } else {
            ContentUnavailableView("Выберите запись", systemImage: "square.and.pencil")
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Picker("Период", selection: $period) {
                ForEach(Period.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Категория", selection: $journal.filter.category) {
                Text("Все категории").tag(UUID?.none)
                ForEach(journal.categories) { Text($0.name).tag(UUID?.some($0.id)) }
            }
            Picker("Тег", selection: $journal.filter.tag) {
                Text("Все теги").tag(UUID?.none)
                ForEach(journal.tags) { Text("#" + $0.name).tag(UUID?.some($0.id)) }
            }
            Menu("Экспорт", systemImage: "square.and.arrow.up") {
                Button("CSV…") { ExportActions.exportCSV(journal.exportRows()) }
                Button("SQLite…") { ExportActions.exportSQLite(journal.exportRows()) }
            }
            Button("Добавить запись", systemImage: "plus") { showingAddSheet = true }
        }
    }

    /// Arrow keys: move through all entries in on-screen order (days flattened).
    private func moveSelection(by step: Int, proxy: ScrollViewProxy) -> KeyPress.Result {
        let ids = journal.groups.flatMap(\.entries).map(\.id)
        guard let next = JournalSelection.next(from: selection, in: ids, step: step) else { return .ignored }
        selection = next
        proxy.scrollTo(next)
        return .handled
    }

    private func applyPeriod() {
        guard let days = period.days else {
            journal.filter.from = nil
            journal.filter.to = nil
            return
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: model.now)
        journal.filter.from = calendar.date(byAdding: .day, value: -days, to: today)
        journal.filter.to = nil
    }
}
