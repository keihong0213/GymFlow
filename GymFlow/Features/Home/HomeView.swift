import SwiftUI
import GymFlowCore

struct HomeView: View {
    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(SettingsStore.self) private var settings
    @Environment(\.locale) private var locale

    @State private var model = HomeViewModel()
    @State private var activeSession: ActiveSession?
    @State private var showRoutines = false
    @State private var showSettings = false
    @State private var pastWorkout: Workout?
    @State private var showHistory = false
    @State private var dayPicker: DayWorkoutsPick?

    struct DayWorkoutsPick: Identifiable {
        let workouts: [Workout]
        var id: String { workouts.map { $0.id.uuidString }.joined() }
    }

    struct ActiveSession: Identifiable {
        let workout: Workout
        let prefilledPRs: [DetectedPR]
        var id: UUID { workout.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    daysSection
                    workoutSection
                    Spacer().frame(height: 8)
                    startButton
                    templatesButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("app.title")
            .toolbar { toolbarContent }
            .navigationDestination(item: $pastWorkout) { workout in
                PastWorkoutDetailView(workout: workout)
                    .environment(bootstrap)
                    .environment(settings)
                    .environment(\.locale, settings.effectiveLocale)
            }
            .confirmationDialog(
                "home.multiple_workouts_title",
                isPresented: Binding(
                    get: { dayPicker != nil },
                    set: { if !$0 { dayPicker = nil } }
                ),
                titleVisibility: .visible,
                presenting: dayPicker
            ) { pick in
                ForEach(pick.workouts) { workout in
                    Button(workoutTimeLabel(workout)) {
                        dayPicker = nil
                        pastWorkout = workout
                    }
                }
                Button("common.cancel", role: .cancel) {}
            }
            .navigationDestination(isPresented: $showHistory) {
                WorkoutHistoryView()
                    .environment(bootstrap)
                    .environment(settings)
                    .environment(\.locale, settings.effectiveLocale)
            }
        }
        .task {
            model.load(bootstrap: bootstrap)
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--demo-active-session"), activeSession == nil {
                if let workout = try? DemoDataSeeder.seedActiveSession(bootstrap: bootstrap) {
                    activeSession = ActiveSession(workout: workout, prefilledPRs: [])
                }
            } else if args.contains("--demo-summary"), activeSession == nil {
                if let result = try? DemoDataSeeder.seedFinishedSession(bootstrap: bootstrap) {
                    activeSession = ActiveSession(workout: result.0, prefilledPRs: result.1)
                }
            } else if args.contains("--open-session"), activeSession == nil {
                startWorkout()
            } else if args.contains("--open-routines"), !showRoutines {
                showRoutines = true
            }
            #endif
        }
        .fullScreenCover(item: $activeSession) { session in
            SessionView(
                workout: session.workout,
                bootstrap: bootstrap,
                prefilledPRs: session.prefilledPRs
            )
            .environment(bootstrap)
            .environment(settings)
            .environment(\.locale, settings.effectiveLocale)
            .onDisappear { model.load(bootstrap: bootstrap) }
        }
        .sheet(isPresented: $showRoutines) {
            RoutinesView { routine in
                showRoutines = false
                startFromRoutine(routine)
            }
            .environment(bootstrap)
            .environment(settings)
            .environment(\.locale, settings.effectiveLocale)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(bootstrap)
                .environment(settings)
                .environment(\.locale, settings.effectiveLocale)
        }
    }

    @ViewBuilder
    private var daysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.recent_7_days")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            DaysStripView(
                days: model.last7Days(),
                activeDays: model.activeDays,
                locale: locale,
                onTapDay: openWorkout(on:)
            )
        }
    }

    @ViewBuilder
    private var workoutSection: some View {
        if let summary = model.lastSummary {
            LastWorkoutCard(summary: summary, locale: locale)
        } else {
            emptyStateCard
        }
    }

    private var emptyStateCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("home.no_workouts_title")
                .font(.headline)
            Text("home.no_workouts_subtitle")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var startButton: some View {
        Button {
            startWorkout()
        } label: {
            Text("home.start_workout")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(.accentColor)
        .accessibilityIdentifier("home.start_workout")
    }

    private var templatesButton: some View {
        Button {
            showRoutines = true
        } label: {
            Text("home.from_template")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.bordered)
        .tint(.accentColor)
    }

    private func openWorkout(on day: Date) {
        let workouts = (try? bootstrap.workoutRepo.completedWorkouts(on: day)) ?? []
        if workouts.count == 1 {
            pastWorkout = workouts[0]
        } else if workouts.count > 1 {
            dayPicker = DayWorkoutsPick(workouts: workouts)
        }
    }

    private func workoutTimeLabel(_ workout: Workout) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("jmm")
        return f.string(from: workout.startedAt)
    }

    private func startWorkout() {
        do {
            let workout = try bootstrap.workoutRepo.start()
            bootstrap.analytics.log(AnalyticsEventType.workoutStarted, payload: ["source": "blank"])
            activeSession = ActiveSession(workout: workout, prefilledPRs: [])
        } catch {
            // swallow: in practice log / show alert
        }
    }

    private func startFromRoutine(_ routine: Routine) {
        do {
            let workout = try bootstrap.workoutRepo.startFromRoutine(routineId: routine.id)
            bootstrap.analytics.log(
                AnalyticsEventType.workoutStarted,
                payload: ["source": "routine", "routine_id": routine.id.uuidString]
            )
            activeSession = ActiveSession(workout: workout, prefilledPRs: [])
        } catch {
            // swallow
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("settings.title")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showHistory = true
            } label: {
                Image(systemName: "clock.arrow.circlepath")
            }
            .accessibilityLabel("history.title")
            .accessibilityIdentifier("home.history")
        }
        #if DEBUG
        ToolbarItem(placement: .topBarLeading) {
            debugMenu
                .accessibilityLabel("a11y.debug_menu")
        }
        #endif
    }

    #if DEBUG
    private var debugMenu: some View {
        Menu {
            Button {
                try? DemoDataSeeder.seed(bootstrap: bootstrap)
                model.load(bootstrap: bootstrap)
            } label: {
                Label("debug.seed_demo", systemImage: "flask")
            }
            Button(role: .destructive) {
                try? DemoDataSeeder.clearWorkouts(bootstrap: bootstrap)
                model.load(bootstrap: bootstrap)
            } label: {
                Label("debug.clear_workouts", systemImage: "trash")
            }
        } label: {
            Image(systemName: "hammer")
        }
    }
    #endif
}
