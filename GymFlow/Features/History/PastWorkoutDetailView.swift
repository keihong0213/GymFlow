import SwiftUI
import GymFlowCore

struct PastWorkoutDetailView: View {
    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(SettingsStore.self) private var settings
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss

    let workout: Workout

    @State private var summary: WorkoutSummary?
    @State private var exercises: [ExerciseBlock] = []
    @State private var editing: EditingSetItem?
    @State private var showDeleteWorkoutConfirm = false

    struct ExerciseBlock: Identifiable {
        let id: UUID
        let exercise: Exercise
        let sets: [SetEntry]
    }

    private var unit: WeightUnit { settings.units }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                statsRow
                if !exercises.isEmpty {
                    exercisesSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(titleString)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteWorkoutConfirm = true
                    } label: {
                        Label("past_workout.delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("past_workout.more")
            }
        }
        .confirmationDialog(
            "past_workout.delete_confirm",
            isPresented: $showDeleteWorkoutConfirm,
            titleVisibility: .visible
        ) {
            Button("past_workout.delete", role: .destructive) {
                _ = try? bootstrap.workoutRepo.deleteWorkout(id: workout.id)
                dismiss()
            }
            Button("common.cancel", role: .cancel) {}
        }
        .sheet(item: $editing) { item in
            EditSetSheet(
                set: item.entry,
                category: item.exercise.category,
                onSaveStrength: { kg, reps in
                    try? bootstrap.workoutRepo.replaceStrengthSet(id: item.entry.id, weightKg: kg, reps: reps)
                    load()
                },
                onSaveBodyweight: { reps in
                    try? bootstrap.workoutRepo.replaceStrengthSet(id: item.entry.id, weightKg: 0, reps: reps)
                    load()
                },
                onSaveCardio: { duration, distance in
                    try? bootstrap.workoutRepo.replaceCardioSet(id: item.entry.id, durationSec: duration, distanceMeters: distance)
                    load()
                },
                onDelete: {
                    _ = try? bootstrap.workoutRepo.deleteSet(id: item.entry.id)
                    load()
                }
            )
            .environment(settings)
        }
        .task { load() }
    }

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text(durationString)
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .monospacedDigit()
            Text(workout.startedAt.formatted(date: .complete, time: .shortened))
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

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("summary.exercises_section")
                .font(.subheadline.weight(.semibold))
            VStack(spacing: 12) {
                ForEach(exercises) { block in
                    exerciseCard(block)
                }
            }
        }
    }

    @ViewBuilder
    private func exerciseCard(_ block: ExerciseBlock) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink {
                ExerciseDetailView(exercise: block.exercise)
                    .environment(bootstrap)
            } label: {
                HStack(spacing: 8) {
                    Text(bootstrap.localizer.displayName(for: block.exercise, locale: locale))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            let category = block.exercise.category
            VStack(spacing: 0) {
                ForEach(Array(block.sets.enumerated()), id: \.element.id) { index, set in
                    Button {
                        editing = EditingSetItem(entry: set, exercise: block.exercise)
                    } label: {
                        setRow(index: index, set: set, category: category)
                    }
                    .buttonStyle(.plain)
                    if set.id != block.sets.last?.id {
                        Divider().padding(.leading, 32)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    @ViewBuilder
    private func setRow(index: Int, set: SetEntry, category: ExerciseCategory) -> some View {
        HStack(spacing: 12) {
            Text("\(set.setNumber)")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 20, alignment: .leading)
            if set.isWarmup {
                Text("past_workout.warmup")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Color.secondary.opacity(0.15))
                    )
                    .foregroundStyle(.secondary)
            }
            switch category {
            case .cardio:
                Text(durationString(for: set.durationSec ?? 0))
                    .font(.callout.weight(.medium))
                    .monospacedDigit()
                if let meters = set.distanceMeters, meters > 0 {
                    Text(verbatim: "·").foregroundStyle(.secondary)
                    Text(distanceString(meters: meters))
                        .font(.callout.weight(.medium))
                        .monospacedDigit()
                }
            case .bodyweight:
                Text("\(set.reps)")
                    .font(.callout.weight(.medium))
                    .monospacedDigit()
                Text("session.reps_unit")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            default:
                Text(weightString(for: set.weightKg))
                    .font(.callout.weight(.medium))
                    .monospacedDigit()
                Text(verbatim: "×").foregroundStyle(.secondary)
                Text("\(set.reps)")
                    .font(.callout.weight(.medium))
                    .monospacedDigit()
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func durationString(for sec: Int) -> String {
        WorkoutFormatters.duration(fromSeconds: sec)
    }

    private func distanceString(meters: Double) -> String {
        WorkoutFormatters.distance(meters: meters, locale: locale)
    }

    private var titleString: String {
        workout.startedAt.formatted(.dateTime.locale(locale).year().month().day())
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

    private func load() {
        summary = try? bootstrap.workoutRepo.summary(for: workout.id)
        let rows = (try? bootstrap.workoutRepo.exercises(for: workout.id)) ?? []
        var built: [ExerciseBlock] = []
        for row in rows {
            guard let ex = (try? bootstrap.exerciseRepo.find(id: row.exerciseId)) ?? nil else { continue }
            let sets = (try? bootstrap.workoutRepo.sets(for: row.id)) ?? []
            built.append(ExerciseBlock(id: row.id, exercise: ex, sets: sets))
        }
        exercises = built
    }
}
