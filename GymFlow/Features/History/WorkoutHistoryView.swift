import SwiftUI
import GymFlowCore

struct WorkoutHistoryView: View {
    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(SettingsStore.self) private var settings
    @Environment(\.locale) private var locale

    @State private var rows: [Row] = []
    @State private var loaded = false
    @State private var showCalendar = false

    struct Row: Identifiable {
        let workout: Workout
        let summary: WorkoutSummary
        var id: UUID { workout.id }
    }

    private var unit: WeightUnit { settings.units }

    var body: some View {
        Group {
            if rows.isEmpty && loaded {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("history.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCalendar = true
                } label: {
                    Image(systemName: "calendar")
                }
                .accessibilityLabel("history.show_calendar")
            }
        }
        .navigationDestination(isPresented: $showCalendar) {
            WorkoutCalendarView()
                .environment(bootstrap)
                .environment(settings)
                .environment(\.locale, settings.effectiveLocale)
        }
        .task { load() }
    }

    private var list: some View {
        List {
            ForEach(groupedRows, id: \.key) { group in
                Section(header: Text(group.key)) {
                    ForEach(group.rows) { row in
                        NavigationLink {
                            PastWorkoutDetailView(workout: row.workout)
                                .environment(bootstrap)
                                .environment(settings)
                                .environment(\.locale, settings.effectiveLocale)
                        } label: {
                            rowLabel(row)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                _ = try? bootstrap.workoutRepo.deleteWorkout(id: row.workout.id)
                                load()
                            } label: {
                                Label("common.delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func rowLabel(_ row: Row) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayString(row.workout.startedAt))
                    .font(.subheadline.weight(.semibold))
                Text(subtitleString(row))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(volumeString(row.summary.totalVolumeKg))
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("history.empty_title")
                .font(.headline)
            Text("history.empty_subtitle")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var groupedRows: [(key: String, rows: [Row])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: rows) { row -> DateComponents in
            calendar.dateComponents([.year, .month], from: row.workout.startedAt)
        }
        let sortedKeys = groups.keys.sorted { lhs, rhs in
            let l = calendar.date(from: lhs) ?? .distantPast
            let r = calendar.date(from: rhs) ?? .distantPast
            return l > r
        }
        return sortedKeys.map { key in
            let date = calendar.date(from: key) ?? Date()
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.setLocalizedDateFormatFromTemplate("yMMMM")
            return (formatter.string(from: date), groups[key] ?? [])
        }
    }

    private func dayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("EEEE, d MMM")
        return f.string(from: date)
    }

    private func subtitleString(_ row: Row) -> String {
        let duration = durationString(row.workout)
        let ex = row.summary.exerciseCount
        let sets = row.summary.setCount
        return "\(duration) · \(ex) · \(sets)"
    }

    private func durationString(_ workout: Workout) -> String {
        guard let ended = workout.endedAt else { return "—" }
        let t = Int(ended.timeIntervalSince(workout.startedAt))
        let h = t / 3600
        let m = (t % 3600) / 60
        if h > 0 { return String(format: "%dh %dm", h, m) }
        return String(format: "%dm", m)
    }

    private func volumeString(_ kg: Double) -> String {
        let value = unit.fromKg(kg)
        let nf = NumberFormatter()
        nf.locale = locale
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 0
        let num = nf.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(num) \(unit.rawValue)"
    }

    private func load() {
        let workouts = (try? bootstrap.workoutRepo.completedWorkouts()) ?? []
        var built: [Row] = []
        for w in workouts {
            if let s = try? bootstrap.workoutRepo.summary(for: w.id) {
                built.append(Row(workout: w, summary: s))
            }
        }
        rows = built
        loaded = true
    }
}
