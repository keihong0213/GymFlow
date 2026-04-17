import SwiftUI
import GymFlowCore

struct SessionSummaryView: View {
    let workout: Workout
    let detectedPRs: [DetectedPR]
    let bootstrap: AppBootstrap
    let locale: Locale
    let unit: WeightUnit
    let onDone: () -> Void

    @State private var exercises: [ExerciseBreakdown] = []
    @State private var summary: WorkoutSummary?
    @State private var exerciseNames: [UUID: String] = [:]

    struct ExerciseBreakdown: Identifiable {
        let id: UUID
        let exercise: Exercise
        let topSet: SetEntry?
        let volumeKg: Double
        let setCount: Int
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                statsRow
                if !detectedPRs.isEmpty {
                    prSection
                }
                if !exercises.isEmpty {
                    exercisesSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("summary.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("common.done") { onDone() }
                    .fontWeight(.semibold)
            }
        }
        .task { load() }
    }

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text(durationString)
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text(workout.startedAt, style: .date)
                .foregroundStyle(.secondary)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard("summary.volume", value: volumeString)
            statCard("summary.sets", value: "\(summary?.setCount ?? 0)")
            statCard("summary.exercises", value: "\(summary?.exerciseCount ?? 0)")
        }
    }

    @ViewBuilder
    private func statCard(_ titleKey: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titleKey)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var prSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Color.yellow)
                Text("summary.new_prs")
                    .font(.subheadline.weight(.semibold))
            }
            VStack(spacing: 0) {
                ForEach(Array(detectedPRs.enumerated()), id: \.offset) { _, pr in
                    prRow(pr)
                    if pr.record.id != detectedPRs.last?.record.id {
                        Divider().padding(.leading, 12)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
    }

    @ViewBuilder
    private func prRow(_ pr: DetectedPR) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exerciseName(for: pr.record.exerciseId))
                    .font(.subheadline.weight(.medium))
                Text(prTypeLabel(for: pr.record.type))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(prValueString(for: pr))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                if let previous = pr.previousValueKg {
                    Text("summary.previous \(weightString(for: previous))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("summary.first_time")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("summary.exercises_section")
                .font(.subheadline.weight(.semibold))
            VStack(spacing: 0) {
                ForEach(exercises) { row in
                    NavigationLink {
                        ExerciseDetailView(exercise: row.exercise, unit: unit)
                            .environment(bootstrap)
                    } label: {
                        exerciseRow(row)
                    }
                    .buttonStyle(.plain)
                    if row.id != exercises.last?.id {
                        Divider().padding(.leading, 12)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
    }

    @ViewBuilder
    private func exerciseRow(_ row: ExerciseBreakdown) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(bootstrap.localizer.displayName(for: row.exercise, locale: locale))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                if let top = row.topSet {
                    Text("summary.top_set \(weightString(for: top.weightKg)) \(top.reps)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("summary.sets_count \(row.setCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }

    private var durationString: String {
        guard let ended = workout.endedAt else { return "0:00" }
        let t = Int(ended.timeIntervalSince(workout.startedAt))
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    private var volumeString: String {
        let kg = summary?.totalVolumeKg ?? 0
        let value = unit.fromKg(kg)
        let nf = NumberFormatter()
        nf.locale = locale
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 0
        let num = nf.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(num) \(unit.rawValue)"
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

    private func exerciseName(for id: UUID) -> String {
        exerciseNames[id] ?? ""
    }

    private func prTypeLabel(for type: PRType) -> LocalizedStringKey {
        switch type {
        case .weight: return "summary.pr_type.weight"
        case .e1rm: return "summary.pr_type.e1rm"
        }
    }

    private func prValueString(for pr: DetectedPR) -> String {
        switch pr.record.type {
        case .weight:
            return "\(weightString(for: pr.record.weightKg)) × \(pr.record.reps)"
        case .e1rm:
            return weightString(for: pr.record.valueKg)
        }
    }

    private func load() {
        summary = try? bootstrap.workoutRepo.summary(for: workout.id)
        let rows = (try? bootstrap.workoutRepo.exercises(for: workout.id)) ?? []
        var built: [ExerciseBreakdown] = []
        var names: [UUID: String] = [:]
        for row in rows {
            guard let ex = (try? bootstrap.exerciseRepo.find(id: row.exerciseId)) ?? nil else { continue }
            names[ex.id] = bootstrap.localizer.displayName(for: ex, locale: locale)
            let sets = (try? bootstrap.workoutRepo.sets(for: row.id)) ?? []
            let working = sets.filter { !$0.isWarmup }
            let top = working.max(by: { $0.estimatedOneRepMaxKg < $1.estimatedOneRepMaxKg })
            let volume = working.reduce(0.0) { $0 + $1.volumeKg }
            built.append(ExerciseBreakdown(
                id: row.id,
                exercise: ex,
                topSet: top,
                volumeKg: volume,
                setCount: working.count
            ))
        }
        for pr in detectedPRs where names[pr.record.exerciseId] == nil {
            if let ex = (try? bootstrap.exerciseRepo.find(id: pr.record.exerciseId)) ?? nil {
                names[pr.record.exerciseId] = bootstrap.localizer.displayName(for: ex, locale: locale)
            }
        }
        exercises = built
        exerciseNames = names
    }
}
