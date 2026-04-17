import SwiftUI
import GymFlowCore

@main
struct GymFlowApp: App {
    @State private var bootstrap: AppBootstrap?
    @State private var bootstrapError: String?
    @State private var language = LanguageManager()

    var body: some Scene {
        WindowGroup {
            rootView
                .environment(\.locale, language.effectiveLocale)
                .environment(language)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if let bootstrap {
            HomeView()
                .environment(bootstrap)
        } else if let error = bootstrapError {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                Text(error)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            .padding()
        } else {
            ProgressView("loading")
                .task { await boot() }
        }
    }

    private func boot() async {
        do {
            let instance = try AppBootstrap()
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--reset-workouts") {
                try? instance.workoutRepo.deleteAll()
            }
            if args.contains("--seed-demo") {
                try? DemoDataSeeder.seed(bootstrap: instance)
            }
            #endif
            bootstrap = instance
        } catch {
            bootstrapError = String(describing: error)
        }
    }
}
