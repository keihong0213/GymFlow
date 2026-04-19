import SwiftUI
import GymFlowCore

struct WorkoutCalendarView: View {
    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(SettingsStore.self) private var settings
    @Environment(\.locale) private var locale

    @State private var anchor: Date = Date()
    @State private var activeDays: Set<Date> = []
    @State private var selected: Workout?

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = locale
        c.firstWeekday = Calendar.current.firstWeekday
        return c
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthHeader
                weekdayRow
                grid
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("history.calendar_title")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selected) { workout in
            PastWorkoutDetailView(workout: workout)
                .environment(bootstrap)
                .environment(settings)
                .environment(\.locale, settings.effectiveLocale)
        }
        .onAppear { loadMonth() }
        .onChange(of: anchor) { _, _ in loadMonth() }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
            }
            .accessibilityLabel("history.previous_month")
            Spacer()
            Text(monthTitle)
                .font(.title3.weight(.semibold))
            Spacer()
            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
            }
            .accessibilityLabel("history.next_month")
            .disabled(isViewingCurrentMonth)
            .opacity(isViewingCurrentMonth ? 0.35 : 1)
        }
        .padding(.horizontal, 4)
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdayShortLabels, id: \.self) { label in
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        let days = gridDays
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                dayCell(day)
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ info: DayInfo) -> some View {
        let isActive = info.inMonth && activeDays.contains(calendar.startOfDay(for: info.date))
        let isToday = calendar.isDateInToday(info.date)
        Group {
            if isActive {
                Button {
                    if let workout = try? bootstrap.workoutRepo.completedWorkout(on: info.date) {
                        selected = workout
                    }
                } label: {
                    content(info: info, isActive: true, isToday: isToday)
                }
                .buttonStyle(.plain)
            } else {
                content(info: info, isActive: false, isToday: isToday)
            }
        }
    }

    @ViewBuilder
    private func content(info: DayInfo, isActive: Bool, isToday: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isActive ? Color.accentColor.opacity(0.18) : Color.clear)
            if isToday {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.accentColor, lineWidth: 1.5)
            }
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: info.date))")
                    .font(.footnote.weight(isToday ? .bold : .medium))
                    .foregroundStyle(info.inMonth ? (isActive ? Color.accentColor : Color.primary) : Color.secondary.opacity(0.4))
                Circle()
                    .fill(isActive ? Color.accentColor : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .padding(.vertical, 6)
        }
        .frame(height: 44)
        .contentShape(Rectangle())
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter.string(from: anchor)
    }

    private var weekdayShortLabels: [String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? []
        // Reorder to firstWeekday
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    struct DayInfo {
        let date: Date
        let inMonth: Bool
    }

    private var gridDays: [DayInfo] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: anchor) else { return [] }
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        let firstCell = calendar.date(byAdding: .day, value: -leading, to: firstOfMonth) ?? firstOfMonth
        var days: [DayInfo] = []
        for offset in 0..<42 {
            if let d = calendar.date(byAdding: .day, value: offset, to: firstCell) {
                days.append(DayInfo(date: d, inMonth: calendar.isDate(d, equalTo: anchor, toGranularity: .month)))
            }
        }
        return days
    }

    private var isViewingCurrentMonth: Bool {
        calendar.isDate(anchor, equalTo: Date(), toGranularity: .month)
    }

    private func shiftMonth(by delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: anchor) {
            anchor = next
        }
    }

    private func loadMonth() {
        guard let monthInterval = calendar.dateInterval(of: .month, for: anchor) else {
            activeDays = []
            return
        }
        let workouts = (try? bootstrap.workoutRepo.completedWorkouts(in: monthInterval)) ?? []
        activeDays = Set(workouts.map { calendar.startOfDay(for: $0.startedAt) })
    }
}
