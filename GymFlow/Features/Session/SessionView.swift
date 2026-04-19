import SwiftUI
import GymFlowCore

struct SessionView: View {
    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(SettingsStore.self) private var settings
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss

    @State private var coordinator: SessionCoordinator
    @State private var showExercisePicker = false
    @State private var showEndConfirm = false
    @State private var endFailed = false
    @State private var editing: EditingSet?

    struct EditingSet: Identifiable {
        let entry: SetEntry
        let exercise: Exercise
        var id: UUID { entry.id }
    }

    init(
        workout: Workout,
        bootstrap: AppBootstrap,
        prefilledPRs: [DetectedPR] = []
    ) {
        let coordinator = SessionCoordinator(
            workout: workout,
            workoutRepo: bootstrap.workoutRepo,
            exerciseRepo: bootstrap.exerciseRepo,
            prCalculator: bootstrap.prCalculator,
            defaultRestSeconds: bootstrap.settingsStore.defaultRestSeconds,
            analytics: bootstrap.analytics
        )
        coordinator.lastDetectedPRs = prefilledPRs
        _coordinator = State(initialValue: coordinator)
    }

    var body: some View {
        NavigationStack {
            Group {
                if coordinator.workout.endedAt == nil {
                    sessionContent
                } else {
                    SessionSummaryView(
                        workout: coordinator.workout,
                        detectedPRs: coordinator.lastDetectedPRs,
                        bootstrap: bootstrap,
                        locale: locale,
                        onDone: { dismiss() }
                    )
                }
            }
        }
        .interactiveDismissDisabled(true)
        .task {
            coordinator.loadExistingContents()
            coordinator.startTicking()
        }
        .onDisappear { coordinator.stopTicking() }
    }

    private var sessionContent: some View {
        List {
            ForEach(coordinator.exercises) { section in
                SessionExerciseSection(
                    section: section,
                    locale: locale,
                    localizer: bootstrap.localizer,
                    onLogSet: { weightKg, reps in
                        try? coordinator.logSet(
                            sectionId: section.workoutExerciseId,
                            weightKg: weightKg,
                            reps: reps
                        )
                    },
                    onLogCardioSet: { duration, distance in
                        try? coordinator.logCardioSet(
                            sectionId: section.workoutExerciseId,
                            durationSec: duration,
                            distanceMeters: distance
                        )
                    },
                    onDeleteSet: { id in
                        try? coordinator.deleteSet(id: id)
                    },
                    onEditSet: { set in
                        editing = EditingSet(entry: set, exercise: section.exercise)
                    }
                )
            }

            Section {
                Button {
                    showExercisePicker = true
                } label: {
                    Label("session.add_exercise", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            if let remaining = coordinator.restRemaining {
                RestTimerPill(remaining: remaining, onCancel: coordinator.cancelRest)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: coordinator.restRemaining)
        .navigationTitle(elapsedString)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("common.cancel") {
                    showEndConfirm = true
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("session.end") {
                    showEndConfirm = true
                }
                .fontWeight(.semibold)
                .accessibilityIdentifier("session.end")
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { exercise in
                try? coordinator.addExercise(exercise)
                showExercisePicker = false
            }
        }
        .sheet(item: $editing) { item in
            EditSetSheet(
                set: item.entry,
                category: item.exercise.category,
                onSaveStrength: { kg, reps in
                    try? coordinator.editSet(id: item.entry.id, weightKg: kg, reps: reps)
                },
                onSaveBodyweight: { reps in
                    try? coordinator.editSet(id: item.entry.id, weightKg: 0, reps: reps)
                },
                onSaveCardio: { duration, distance in
                    try? coordinator.editCardioSet(id: item.entry.id, durationSec: duration, distanceMeters: distance)
                },
                onDelete: {
                    try? coordinator.deleteSet(id: item.entry.id)
                }
            )
            .environment(settings)
        }
        .confirmationDialog(
            "session.end_confirm",
            isPresented: $showEndConfirm,
            titleVisibility: .visible
        ) {
            Button("session.end", role: .destructive) {
                do {
                    try coordinator.end()
                } catch {
                    endFailed = true
                }
            }
            .accessibilityIdentifier("session.end_confirm")
            Button("common.cancel", role: .cancel) {}
        }
        .alert("session.end_failed", isPresented: $endFailed) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("session.end_failed_message")
        }
    }

    private var elapsedString: String {
        let t = Int(coordinator.elapsed)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
