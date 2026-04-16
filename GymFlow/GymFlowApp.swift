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
            ContentView()
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
            bootstrap = try AppBootstrap()
        } catch {
            bootstrapError = String(describing: error)
        }
    }
}
