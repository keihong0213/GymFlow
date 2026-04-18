import SwiftUI
import MetricKit
import GymFlowCore

@main
struct GymFlowApp: App {
    @State private var bootstrap: AppBootstrap?
    @State private var bootstrapError: String?
    private let metricsLogger: MetricsLogger

    init() {
        let logger = MetricsLogger()
        MXMetricManager.shared.add(logger)
        self.metricsLogger = logger
    }

    var body: some Scene {
        WindowGroup {
            if let bootstrap {
                RootView(bootstrap: bootstrap)
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

private struct RootView: View {
    let bootstrap: AppBootstrap
    @AppStorage("onboarding.seen") private var hasSeenOnboarding = false

    var body: some View {
        @Bindable var store = bootstrap.settingsStore
        return Group {
            if hasSeenOnboarding || RootView.shouldBypassOnboarding {
                HomeView()
                    .environment(bootstrap)
                    .environment(store)
            } else {
                OnboardingView { hasSeenOnboarding = true }
            }
        }
        .environment(\.locale, store.effectiveLocale)
        .preferredColorScheme(store.preferredColorScheme)
    }

    private static var shouldBypassOnboarding: Bool {
        #if DEBUG
        let bypassArgs: Set<String> = [
            "--open-session",
            "--open-routines",
            "--demo-summary",
            "--demo-active-session",
            "--seed-demo",
            "--skip-onboarding",
        ]
        return !Set(ProcessInfo.processInfo.arguments).isDisjoint(with: bypassArgs)
        #else
        return false
        #endif
    }
}
