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
                        EntryRow(entry: entry, now: model.now, isSelected: selection == entry.id)
                            .tag(entry.id)
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    DayHeader(group: group, now: model.now)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .overlay {
            if journal.groups.isEmpty {
                Text(journal.filter == EntryFilter() ? "Записей пока нет." : "Ничего не найдено.")
                    .typeRole(.body)
                    .foregroundStyle(Color.textSecondary)
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

/// Day name and date on the left, the day's total «в фокусе» on the right.
/// A plain function component: it renders from `group` and `now` only.
private struct DayHeader: View {
    let group: DayGroup
    let now: Date

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .typeRole(.bodyEmphasis)
                    .foregroundStyle(Color.textPrimary)
                Text(group.day.formatted(.dateTime.day().month(.wide)))
                    .typeRole(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: Space.x2)
            VStack(alignment: .trailing, spacing: 0) {
                Text(DurationFormat.short(group.liveTotal(at: now)))
                    .typeRole(.dayTotal)
                    .foregroundStyle(Color.textPrimary)
                    .tabularFigures()
                    .lineLimit(1)
                Text("в фокусе")
                    .typeRole(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, Space.x2)
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(group.day) { return "Сегодня" }
        if calendar.isDateInYesterday(group.day) { return "Вчера" }
        return group.day.formatted(.dateTime.weekday(.wide))
    }
}

/// One journal row: a single 44px line. Like a small function component that
/// receives `entry` and `now` as props and renders from them only.
private struct EntryRow: View {
    let entry: TimeEntry
    let now: Date
    let isSelected: Bool

    private var isRunning: Bool { entry.end == nil }

    var body: some View {
        HStack(spacing: Space.x3) {
            Text(entry.start.formatted(date: .omitted, time: .shortened))
                .typeRole(.caption)
                .foregroundStyle(Color.textSecondary)
                .tabularFigures()
                .lineLimit(1)
                .fixedSize()
            Text(entry.title ?? EntryRowText.untitled)
                .typeRole(.body)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            Spacer(minLength: Space.x2)
            HStack(spacing: Space.x2) {
                CategoryDot(storedHex: entry.category?.colorHex ?? "")
                Text(entry.category?.name ?? "")
                    .typeRole(.body)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            HStack(spacing: Space.x2) {
                if isLong {
                    Text(EntryRowText.longNote)
                        .typeRole(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                        .fixedSize()
                }
                Text(DurationFormat.short(duration))
                    .typeRole(isRunning ? .bodyEmphasis : .body)
                    .foregroundStyle(isRunning ? Color.textPrimary : Color.textSecondary)
                    .tabularFigures()
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .padding(.horizontal, Space.x2)
        .frame(height: Space.rowHeight)
        .background(
            isRunning || isSelected ? Color.surfaceInset : Color.clear,
            in: RoundedRectangle(cornerRadius: Radius.row)
        )
        .overlay {
            if isSelected { Color.clear.hairlineRing(RoundedRectangle(cornerRadius: Radius.row)) }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            EntryRowText.accessibilityLabel(
                title: entry.title, category: entry.category?.name,
                duration: duration, isLong: isLong, isRunning: isRunning))
    }

    private var isLong: Bool {
        LongEntry.isLong(start: entry.start, end: entry.end, now: now)
    }

    private var duration: TimeInterval {
        (entry.end ?? now).timeIntervalSince(entry.start)
    }
}
