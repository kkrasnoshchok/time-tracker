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

    private var selectedEntry: TimeEntry? {
        journal.groups.flatMap(\.entries).first { $0.id == selection }
    }

    var body: some View {
        HSplitView {
            entryList.frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
            detail.frame(minWidth: 360, idealWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
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

    private var entryList: some View {
        List(selection: $selection) {
            ForEach(journal.groups, id: \.day) { group in
                Section {
                    ForEach(group.entries) { entry in
                        EntryRow(entry: entry, now: model.now).tag(entry.id)
                    }
                } header: {
                    DayHeader(group: group)
                }
            }
        }
        .overlay {
            if journal.groups.isEmpty {
                ContentUnavailableView(
                    "Записей нет",
                    systemImage: "clock",
                    description: Text("Начните запись хоткеем или добавьте её вручную.")
                )
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

private struct DayHeader: View {
    let group: DayGroup

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(DurationFormat.short(group.total)).monospacedDigit()
        }
    }

    private var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(group.day) { return "Сегодня" }
        if calendar.isDateInYesterday(group.day) { return "Вчера" }
        return group.day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}

private struct EntryRow: View {
    let entry: TimeEntry
    let now: Date

    var body: some View {
        HStack(spacing: 10) {
            CategoryDot(storedHex: entry.category?.colorHex ?? "")
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title ?? entry.category?.name ?? "Без названия").lineLimit(1)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(entry.end == nil ? "идёт" : DurationFormat.short(duration))
                .monospacedDigit()
                .foregroundStyle(entry.end == nil ? Color.accentColor : Color.secondary)
        }
    }

    private var duration: TimeInterval {
        (entry.end ?? now).timeIntervalSince(entry.start)
    }

    private var subtitle: String {
        let time = entry.start.formatted(date: .omitted, time: .shortened)
            + " – " + (entry.end?.formatted(date: .omitted, time: .shortened) ?? "…")
        let tags = entry.tagList.map(\.name).sorted().map { "#" + $0 }.joined(separator: " ")
        return [entry.category?.name, time, tags.isEmpty ? nil : tags].compactMap { $0 }.joined(separator: " · ")
    }
}
