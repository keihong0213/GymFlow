import SwiftUI

struct DaysStripView: View {
    let days: [Date]
    let activeDays: Set<Date>
    let locale: Locale
    var onTapDay: ((Date) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                dayCell(day)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: Date) -> some View {
        let isActive = activeDays.contains(day)
        let isToday = Calendar.current.isDateInToday(day)
        Group {
            if let onTap = onTapDay, isActive {
                Button {
                    onTap(day)
                } label: {
                    dayCellContent(day: day, isActive: isActive, isToday: isToday)
                }
                .buttonStyle(.plain)
            } else {
                dayCellContent(day: day, isActive: isActive, isToday: isToday)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText(for: day, isActive: isActive, isToday: isToday))
        .accessibilityAddTraits(onTapDay != nil && isActive ? .isButton : [])
    }

    @ViewBuilder
    private func dayCellContent(day: Date, isActive: Bool, isToday: Bool) -> some View {
        VStack(spacing: 6) {
            Text(weekdayLabel(for: day))
                .font(.caption2)
                .foregroundStyle(.secondary)
            ZStack {
                Circle()
                    .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.15))
                    .frame(width: 28, height: 28)
                if isToday {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 2)
                        .frame(width: 34, height: 34)
                }
                Text(dayNumber(for: day))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(isActive ? Color.white : Color.primary)
            }
        }
        .contentShape(Rectangle())
    }

    private func accessibilityText(for day: Date, isActive: Bool, isToday: Bool) -> Text {
        let dateString = formattedFullDate(for: day)
        let todayPrefix: LocalizedStringKey = isToday ? "a11y.day_today \(dateString)" : "a11y.day \(dateString)"
        let status: LocalizedStringKey = isActive ? "a11y.day_trained" : "a11y.day_rest"
        return Text(todayPrefix) + Text(verbatim: " ") + Text(status)
    }

    private func formattedFullDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEd")
        return formatter.string(from: date)
    }

    private func weekdayLabel(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }

    private func dayNumber(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return "\(calendar.component(.day, from: date))"
    }
}
