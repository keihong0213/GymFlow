import SwiftUI
import GymFlowCore

struct RoutinesView: View {
    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss

    let onStart: (Routine) -> Void

    @State private var builtIn: [Routine] = []
    @State private var custom: [Routine] = []
    @State private var showEditor = false
    @State private var editingRoutine: Routine?

    var body: some View {
        NavigationStack {
            List {
                if !builtIn.isEmpty {
                    Section {
                        ForEach(builtIn) { routine in
                            NavigationLink {
                                RoutineDetailView(routine: routine, onStart: { r in
                                    dismiss()
                                    onStart(r)
                                })
                            } label: {
                                RoutineRow(routine: routine)
                            }
                        }
                    } header: {
                        Text("routines.built_in")
                    }
                }

                Section {
                    ForEach(custom) { routine in
                        NavigationLink {
                            RoutineDetailView(
                                routine: routine,
                                onStart: { r in
                                    dismiss()
                                    onStart(r)
                                },
                                onEdit: {
                                    editingRoutine = routine
                                }
                            )
                        } label: {
                            RoutineRow(routine: routine)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                _ = try? bootstrap.routineRepo.delete(id: routine.id)
                                reload()
                            } label: { Label("common.delete", systemImage: "trash") }
                        }
                    }

                    Button {
                        editingRoutine = nil
                        showEditor = true
                    } label: {
                        Label("routines.new", systemImage: "plus.circle.fill")
                            .font(.body.weight(.semibold))
                    }
                } header: {
                    Text("routines.custom")
                }
            }
            .navigationTitle("routines.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showEditor) {
                RoutineEditorView(existing: nil) { reload() }
            }
            .sheet(item: $editingRoutine) { routine in
                RoutineEditorView(existing: routine) { reload() }
            }
        }
        .task { reload() }
    }

    private func reload() {
        builtIn = (try? bootstrap.routineRepo.builtIn()) ?? []
        custom = (try? bootstrap.routineRepo.custom()) ?? []
    }
}

private struct RoutineRow: View {
    let routine: Routine
    @Environment(AppBootstrap.self) private var bootstrap

    @State private var count: Int = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: routine.isBuiltIn ? "sparkles" : "list.bullet.rectangle")
                .foregroundStyle(routine.isBuiltIn ? Color.accentColor : .secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                routineTitleText(routine)
                    .font(.body.weight(.medium))
                if count > 0 {
                    Text("routines.exercises_count \(count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            count = (try? bootstrap.routineRepo.exercises(for: routine.id).count) ?? 0
        }
    }
}
