import SwiftUI
import TimeTrackerCore

/// One journal row: a single 44px line. Like a small function component that
/// receives `entry` and `now` as props and renders from them only.
struct EntryRow: View {
    let entry: TimeEntry
    let now: Date
    let isSelected: Bool

    private var model: EntryRowModel { EntryRowModel(entry: entry, now: now) }
    private var isRunning: Bool { model.isRunning }

    var body: some View {
        HStack(spacing: Space.x3) {
            Text(entry.start.formatted(date: .omitted, time: .shortened))
                .typeRole(.caption)
                .foregroundStyle(secondaryText)
                .tabularFigures()
                .lineLimit(1)
                .fixedSize()
            Text(model.displayTitle)
                .typeRole(.body)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            Spacer(minLength: Space.x2)
            HStack(spacing: Space.x2) {
                CategoryDot(storedHex: entry.category?.colorHex ?? "")
                Text(entry.category?.name ?? "")
                    .typeRole(.body)
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
            }
            HStack(spacing: Space.x2) {
                if isLong {
                    Text(EntryRowText.longNote)
                        .typeRole(.caption)
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)
                        .fixedSize()
                }
                Text(DurationFormat.short(duration))
                    .typeRole(isRunning ? .bodyEmphasis : .body)
                    .foregroundStyle(isRunning ? Color.textPrimary : secondaryText)
                    .tabularFigures()
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .padding(.horizontal, Space.x2)
        .frame(height: Space.rowHeight)
        .background(
            rowFill,
            in: RoundedRectangle(cornerRadius: Radius.row)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityLabel(model.accessibilityLabel)
    }

    /// `text-secondary` is 3.83:1 on `surface-selected` (below AA), so a selected row uses `text-primary`.
    private var secondaryText: Color {
        isSelected && !isRunning ? Color.textPrimary : Color.textSecondary
    }

    /// Running: inset (warm gray). Selected: a cool lavender-gray fill. Never the system blue.
    private var rowFill: Color {
        if isRunning { return Color.surfaceInset }
        return isSelected ? Color.surfaceSelected : Color.clear
    }

    private var isLong: Bool { model.isLong }
    private var duration: TimeInterval { model.duration }
}
