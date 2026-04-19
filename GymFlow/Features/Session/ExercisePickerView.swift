import SwiftUI
import GymFlowCore

struct ExercisePickerView: View {
    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss

    let onPick: (Exercise) -> Void

    @State private var search = ""
    @State private var exercises: [Exercise] = []

    private let categoryOrder: [ExerciseCategory] = [
        .bodyweight, .barbell, .dumbbell, .machine, .cardio, .other
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(categoryOrder, id: \.self) { category in
                    let rows = filtered.filter { $0.category == category }
                    if !rows.isEmpty {
                        Section(categoryTitle(category)) {
                            ForEach(rows) { exercise in
                                Button {
                                    onPick(exercise)
                                } label: {
                                    HStack {
                                        Text(bootstrap.localizer.displayName(for: exercise, locale: locale))
                                            .foregroundStyle(.primary)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: Text("exercise_picker.search_placeholder"))
            .navigationTitle("exercise_picker.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.cancel") { dismiss() }
                }
            }
        }
        .task {
            exercises = (try? bootstrap.exerciseRepo.all()) ?? []
        }
    }

    private var filtered: [Exercise] {
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return exercises }
        return exercises.filter { ex in
            let localized = bootstrap.localizer.displayName(for: ex, locale: locale)
            return localized.localizedCaseInsensitiveContains(trimmed)
                || ex.slug.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
