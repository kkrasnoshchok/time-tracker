import SwiftUI
import TimeTrackerCore

/// Day name and date on the left, the day's total «в фокусе» on the right.
/// A plain function component: it renders from `group` and `now` only.
struct DayHeader: View {
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
