import SwiftUI
import GymFlowCore

struct HomeView: View {
    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(LanguageManager.self) private var language
    @Environment(\.locale) private var locale

    @State private var model = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    daysSection
                    workoutSection
                    Spacer().frame(height: 8)
                    startButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("app.title")
            .toolbar { toolbarContent }
        }
        .task { model.load(bootstrap: bootstrap) }
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
            LastWorkoutCard(summary: summary, locale: locale, unit: .kg)
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
            // Will be wired to Workout Session in PR 5.
        } label: {
            Text("home.start_workout")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(.accentColor)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            languageMenu
        }
        #if DEBUG
        ToolbarItem(placement: .topBarLeading) {
            debugMenu
        }
        #endif
    }

    private var languageMenu: some View {
        @Bindable var languageBinding = language
        return Menu {
            Picker(selection: $languageBinding.selected) {
                Text("language.system").tag(AppLanguage.system)
                Divider()
                Text("language.zh-Hant").tag(AppLanguage.zhHant)
                Text("language.zh-Hans").tag(AppLanguage.zhHans)
                Text("language.en").tag(AppLanguage.en)
                Text("language.ja").tag(AppLanguage.ja)
                Text("language.ko").tag(AppLanguage.ko)
            } label: {
                Text("settings.language")
            }
        } label: {
            Image(systemName: "globe")
        }
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
