import SwiftUI
import GymFlowCore

struct RoutineEditorView: View {
    let existing: Routine?
    let onCompleted: () -> Void

    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var picked: [Exercise] = []
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("routine.name_placeholder", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    if picked.isEmpty {
                        Text("routine.no_exercises_yet")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(picked) { exercise in
                            Text(bootstrap.localizer.displayName(for: exercise, locale: locale))
                        }
                        .onMove { source, destination in
                            picked.move(fromOffsets: source, toOffset: destination)
                        }
                        .onDelete { indices in
                            picked.remove(atOffsets: indices)
                        }
                    }

                    Button {
                        showPicker = true
                    } label: {
                        Label("session.add_exercise", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("routine.exercises")
                }
            }
            .navigationTitle(existing == nil ? "routines.new" : "routine.edit_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common.done") {
                        hideKeyboard()
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .sheet(isPresented: $showPicker) {
                ExercisePickerView { exercise in
                    if !picked.contains(where: { $0.id == exercise.id }) {
                        picked.append(exercise)
                    }
                    showPicker = false
                }
            }
        }
        .task {
            if let existing {
                name = existing.name
                let links = (try? bootstrap.routineRepo.exercises(for: existing.id)) ?? []
                picked = links.compactMap { try? bootstrap.exerciseRepo.find(id: $0.exerciseId) }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !picked.isEmpty
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let ids = picked.map(\.id)
        do {
            if let existing {
                try bootstrap.routineRepo.updateCustom(id: existing.id, name: trimmed, exerciseIds: ids)
            } else {
                _ = try bootstrap.routineRepo.createCustom(name: trimmed, exerciseIds: ids)
            }
            onCompleted()
            dismiss()
        } catch {
            // swallow for MVP; ideally show alert
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
