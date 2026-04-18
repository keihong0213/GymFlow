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
                locale: locale
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

    private func startWorkout() {
        do {
            let workout = try bootstrap.workoutRepo.start()
            activeSession = ActiveSession(workout: workout, prefilledPRs: [])
        } catch {
            // swallow: in practice log / show alert
        }
    }

    private func startFromRoutine(_ routine: Routine) {
        do {
            let workout = try bootstrap.workoutRepo.startFromRoutine(routineId: routine.id)
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
        #if DEBUG
        ToolbarItem(placement: .topBarLeading) {
            debugMenu
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
