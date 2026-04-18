import SwiftUI
import Charts
import GymFlowCore

struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(SettingsStore.self) private var settings
    @Environment(\.locale) private var locale

    @State private var history: [ExerciseHistoryEntry] = []
    @State private var currentPRs: [PRRecord] = []
    @State private var trend: [PRRecord] = []

    private var unit: WeightUnit { settings.units }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if !currentPRs.isEmpty {
                    prSection
                }
                if e1rmTrendPoints.count >= 2 {
                    trendSection
                }
                historySection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(bootstrap.localizer.displayName(for: exercise, locale: locale))
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: categoryIcon)
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(categoryTitle(exercise.category))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var prSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("detail.personal_records")
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 10) {
                ForEach(currentPRs) { record in
                    prCard(record)
                }
            }
        }
    }

    @ViewBuilder
    private func prCard(_ record: PRRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(prTypeTitle(record.type), systemImage: "trophy.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            Text(prValueString(record))
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            Text(record.achievedAt, style: .date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("detail.e1rm_trend")
                .font(.subheadline.weight(.semibold))
            Chart(e1rmTrendPoints) { point in
                LineMark(x: .value("date", point.date), y: .value("e1rm", unit.fromKg(point.value)))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.accentColor)
                PointMark(x: .value("date", point.date), y: .value("e1rm", unit.fromKg(point.value)))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let num = value.as(Double.self) {
                            Text("\(Int(num.rounded())) \(unit.rawValue)")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("detail.recent_history")
                .font(.subheadline.weight(.semibold))
            if history.isEmpty {
                Text("detail.no_history")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
            } else {
                VStack(spacing: 0) {
                    ForEach(history) { entry in
                        historyRow(entry)
                        if entry.id != history.last?.id {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
            }
        }
    }

    @ViewBuilder
    private func historyRow(_ entry: ExerciseHistoryEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.startedAt, style: .date)
                    .font(.subheadline.weight(.medium))
                if let top = entry.topSet {
                    Text("detail.top_set \(weightString(for: top.weightKg)) \(top.reps)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("detail.sets_and_volume \(entry.setCount) \(weightString(for: entry.totalVolumeKg))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }

    private struct TrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    private var e1rmTrendPoints: [TrendPoint] {
        trend
            .filter { $0.type == .e1rm }
            .map { TrendPoint(date: $0.achievedAt, value: $0.valueKg) }
    }

    private var categoryIcon: String {
        switch exercise.category {
        case .barbell: return "dumbbell"
        case .dumbbell: return "dumbbell"
        case .machine: return "gearshape.2"
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .cardio: return "figure.run"
        case .other: return "circle.grid.2x2"
        }
    }

    private func prTypeTitle(_ type: PRType) -> LocalizedStringKey {
        switch type {
        case .weight: return "summary.pr_type.weight"
        case .e1rm: return "summary.pr_type.e1rm"
        }
    }

    private func prValueString(_ record: PRRecord) -> String {
        switch record.type {
        case .weight:
            return "\(weightString(for: record.weightKg)) × \(record.reps)"
        case .e1rm:
            return weightString(for: record.valueKg)
        }
    }

    private func weightString(for kg: Double) -> String {
        let value = unit.fromKg(kg)
        let nf = NumberFormatter()
        nf.locale = locale
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        let num = nf.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(num) \(unit.rawValue)"
    }

    private func load() {
        history = (try? bootstrap.workoutRepo.history(for: exercise.id)) ?? []
        currentPRs = (try? bootstrap.prRepo.currentPRs(for: exercise.id)) ?? []
        trend = (try? bootstrap.prRepo.allPRs(for: exercise.id)) ?? []
    }
}
