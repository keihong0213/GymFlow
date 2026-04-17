import SwiftUI
import GymFlowCore

struct RoutineDetailView: View {
    let routine: Routine
    let onStart: (Routine) -> Void
    var onEdit: (() -> Void)? = nil

    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(\.locale) private var locale

    @State private var entries: [Entry] = []

    struct Entry: Identifiable {
        let id = UUID()
        let exercise: Exercise
        let link: RoutineExercise
    }

    var body: some View {
        List {
            Section {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bootstrap.localizer.displayName(for: entry.exercise, locale: locale))
                            .font(.body.weight(.medium))
                        if let targetText = targetText(for: entry.link) {
                            Text(targetText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                Button {
                    onStart(routine)
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("routine.start")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 16, trailing: 20))

                if let onEdit, !routine.isBuiltIn {
                    Button {
                        onEdit()
                    } label: {
                        Label("common.edit", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(routineTitleString(routine, locale: locale))
        .navigationBarTitleDisplayMode(.inline)
        .task { reload() }
    }

    private func reload() {
        do {
            let links = try bootstrap.routineRepo.exercises(for: routine.id)
            let built: [Entry] = try links.compactMap { link in
                guard let ex = try bootstrap.exerciseRepo.find(id: link.exerciseId) else { return nil }
                return Entry(exercise: ex, link: link)
            }
            entries = built
        } catch {
            entries = []
        }
    }

    private func targetText(for link: RoutineExercise) -> String? {
        guard let sets = link.targetSets else { return nil }
        let sections = link.targetRepsMin.flatMap { min -> String? in
            guard let max = link.targetRepsMax else { return "\(min)" }
            return min == max ? "\(min)" : "\(min)–\(max)"
        }
        if let sections {
            let format = String(localized: "routine.target_sets_reps", locale: locale)
            return String(format: format, locale: locale, sets, sections)
        }
        let format = String(localized: "routine.target_sets", locale: locale)
        return String(format: format, locale: locale, sets)
    }
}
