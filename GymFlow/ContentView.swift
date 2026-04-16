import SwiftUI
import GymFlowCore

struct ContentView: View {
    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(LanguageManager.self) private var language
    @Environment(\.locale) private var locale

    @State private var exercises: [Exercise] = []

    private func categoryTitle(_ category: ExerciseCategory) -> LocalizedStringKey {
        switch category {
        case .barbell: "category.barbell"
        case .dumbbell: "category.dumbbell"
        case .machine: "category.machine"
        case .bodyweight: "category.bodyweight"
        case .cardio: "category.cardio"
        case .other: "category.other"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    let rows = exercises.filter { $0.category == category }
                    if !rows.isEmpty {
                        Section(categoryTitle(category)) {
                            ForEach(rows) { exercise in
                                Text(bootstrap.localizer.displayName(for: exercise, locale: locale))
                            }
                        }
                    }
                }
            }
            .navigationTitle("app.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    languageMenu
                }
            }
        }
        .task {
            exercises = (try? bootstrap.exerciseRepo.all()) ?? []
        }
    }

    @ViewBuilder
    private var languageMenu: some View {
        @Bindable var languageBinding = language
        Menu {
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
}
