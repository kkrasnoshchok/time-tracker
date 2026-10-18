import Foundation
import SwiftData

// Timer and entry operations. Every method validates first and mutates only if all checks pass.
extension TimeStore {
    // MARK: Timer

    public func runningEntry() -> TimeEntry? {
        var descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate { $0.end == nil },
            sortBy: [SortDescriptor(\.start, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// Starts a timer. A running timer is stopped at the new start, so entries never overlap by accident.
    @discardableResult
    public func startTimer(
        category: EntryCategory,
        title: String?,
        tags: [String],
        startedAt: Date? = nil,
        allowOverlap: Bool = false
    ) throws(StoreError) -> TimeEntry {
        let now = time.now()
        let start = startedAt ?? now
        guard start <= now else { throw .startInFuture }

        let running = runningEntry()
        if let running, start < running.start { throw .endBeforeStart }
        if !allowOverlap {
            let clashes = conflicts(for: try makeSpan(start: start, end: nil), excluding: running)
            if !clashes.isEmpty { throw .overlap(clashes.map(\.id)) }
        }

        running?.end = start
        let entry = TimeEntry(start: start, category: category, title: cleaned(title))
        context.insert(entry)
        entry.tags = tagObjects(tags)
        try save()
        return entry
    }

    /// Stops the running timer at "now". If the clock went backwards, the end is clamped to the start.
    @discardableResult
    public func stopTimer() throws(StoreError) -> TimeEntry {
        guard let running = runningEntry() else { throw .noRunningTimer }
        running.end = max(time.now(), running.start)
        try save()
        return running
    }

    // MARK: Manual entries

    @discardableResult
    public func addEntry(
        span: TimeSpan,
        category: EntryCategory,
        title: String?,
        tags: [String],
        notes: String?,
        allowOverlap: Bool = false
    ) throws(StoreError) -> TimeEntry {
        guard span.end != nil else { throw .missingEnd }
        try validate(span, excluding: nil, allowOverlap: allowOverlap)
        let entry = TimeEntry(
            start: span.start, end: span.end, category: category, title: cleaned(title), notes: cleaned(notes)
        )
        context.insert(entry)
        entry.tags = tagObjects(tags)
        try save()
        return entry
    }

    public func update(
        _ entry: TimeEntry,
        span: TimeSpan,
        category: EntryCategory,
        title: String?,
        tags: [String],
        notes: String?,
        allowOverlap: Bool = false
    ) throws(StoreError) {
        if span.end == nil, let other = runningEntry(), other !== entry { throw .overlap([other.id]) }
        try validate(span, excluding: entry, allowOverlap: allowOverlap)
        entry.start = span.start
        entry.end = span.end
        entry.category = category
        entry.title = cleaned(title)
        entry.notes = cleaned(notes)
        entry.tags = tagObjects(tags)
        try save()
    }

    public func delete(_ entry: TimeEntry) throws(StoreError) {
        context.delete(entry)
        try save()
    }

    // MARK: Queries

    /// Entries that overlap `[from, to)`, oldest first. A running entry counts as lasting until now.
    public func conflicts(for span: TimeSpan, excluding: TimeEntry?) -> [TimeEntry] {
        let now = time.now()
        let upper = span.end ?? now
        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate { $0.start < upper },
            sortBy: [SortDescriptor(\.start)]
        )
        let candidates = (try? context.fetch(descriptor)) ?? []
        return candidates.filter { candidate in
            guard candidate !== excluding, let other = try? TimeSpan(start: candidate.start, end: candidate.end) else {
                return false
            }
            return span.overlaps(other, now: now)
        }
    }

    public func entries(from: Date, to: Date) -> [TimeEntry] {
        let farFuture = Date.distantFuture
        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate { $0.start < to && ($0.end ?? farFuture) > from },
            sortBy: [SortDescriptor(\.start)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    public func lastEntry() -> TimeEntry? {
        var descriptor = FetchDescriptor<TimeEntry>(sortBy: [SortDescriptor(\.start, order: .reverse)])
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// Titles ordered by how often they were used, then by how recently.
    public func recentTitles(limit: Int) -> [String] {
        let descriptor = FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.title != nil })
        let entries = (try? context.fetch(descriptor)) ?? []
        var stats: [String: (count: Int, latest: Date)] = [:]
        for entry in entries {
            guard let title = entry.title else { continue }
            let current = stats[title] ?? (0, .distantPast)
            stats[title] = (current.count + 1, max(current.latest, entry.start))
        }
        let ordered = stats.sorted { lhs, rhs in
            lhs.value.count != rhs.value.count ? lhs.value.count > rhs.value.count : lhs.value.latest > rhs.value.latest
        }
        return ordered.prefix(limit).map(\.key)
    }

    // MARK: Helpers

    private func validate(_ span: TimeSpan, excluding entry: TimeEntry?, allowOverlap: Bool) throws(StoreError) {
        let now = time.now()
        guard span.start <= now else { throw .startInFuture }
        if let end = span.end, end > now { throw .endInFuture }
        if !allowOverlap {
            let clashes = conflicts(for: span, excluding: entry)
            if !clashes.isEmpty { throw .overlap(clashes.map(\.id)) }
        }
    }

    private func makeSpan(start: Date, end: Date?) throws(StoreError) -> TimeSpan {
        do {
            return try TimeSpan(start: start, end: end)
        } catch {
            throw .endBeforeStart
        }
    }

    private func cleaned(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private func tagObjects(_ names: [String]) -> [Tag] {
        var seen = Set<String>()
        var result: [Tag] = []
        for raw in names {
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(name.lowercased()).inserted else { continue }
            result.append(tag(named: name))
        }
        return result
    }
}
