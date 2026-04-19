import SwiftUI
import GymFlowCore

struct EditSetSheet: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss

    let set: SetEntry
    let category: ExerciseCategory
    let onSaveStrength: (Double, Int) -> Void
    let onSaveBodyweight: (Int) -> Void
    let onSaveCardio: (Int, Double?) -> Void
    let onDelete: () -> Void

    @State private var weightInput: Double = 0
    @State private var repsInput: Int = 0
    @State private var minutesInput: Int = 0
    @State private var secondsInput: Int = 0
    @State private var distanceKmInput: Double = 0
    @State private var showDeleteConfirm = false

    private var unit: WeightUnit { settings.units }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("edit_set.set_number \(set.setNumber)")) {
                    switch category {
                    case .cardio:
                        cardioRows
                    case .bodyweight:
                        bodyweightRows
                    default:
                        strengthRows
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("common.delete", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("edit_set.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "edit_set.delete_confirm",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("common.delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("common.cancel", role: .cancel) {}
            }
            .onAppear { seed() }
        }
    }

    @ViewBuilder
    private var strengthRows: some View {
        HStack {
            Text("edit_set.weight")
            Spacer()
            TextField("0", value: $weightInput, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
            Text(unit.rawValue).foregroundStyle(.secondary)
        }
        HStack {
            Text("edit_set.reps")
            Spacer()
            TextField("0", value: $repsInput, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
        }
    }

    @ViewBuilder
    private var bodyweightRows: some View {
        HStack {
            Text("edit_set.reps")
            Spacer()
            TextField("0", value: $repsInput, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
        }
    }

    @ViewBuilder
    private var cardioRows: some View {
        HStack {
            Text("edit_set.duration")
            Spacer()
            HStack(spacing: 4) {
                TextField("0", value: $minutesInput, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 50)
                Text(":").foregroundStyle(.secondary)
                TextField("00", value: $secondsInput, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 50)
            }
        }
        HStack {
            Text("edit_set.distance")
            Spacer()
            TextField("0", value: $distanceKmInput, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
            Text("session.distance_unit").foregroundStyle(.secondary)
        }
    }

    private var canSave: Bool {
        switch category {
        case .cardio:
            return (minutesInput * 60 + secondsInput) > 0
        default:
            return repsInput > 0
        }
    }

    private func save() {
        switch category {
        case .cardio:
            let duration = minutesInput * 60 + secondsInput
            guard duration > 0 else { return }
            let meters = distanceKmInput > 0 ? distanceKmInput * 1000 : nil
            onSaveCardio(duration, meters)
        case .bodyweight:
            guard repsInput > 0 else { return }
            onSaveBodyweight(repsInput)
        default:
            guard repsInput > 0 else { return }
            onSaveStrength(unit.toKg(weightInput), repsInput)
        }
        dismiss()
    }

    private func seed() {
        switch category {
        case .cardio:
            let total = set.durationSec ?? 0
            minutesInput = total / 60
            secondsInput = total % 60
            if let meters = set.distanceMeters, meters > 0 {
                distanceKmInput = meters / 1000
            }
        case .bodyweight:
            repsInput = set.reps
        default:
            weightInput = unit.fromKg(set.weightKg)
            repsInput = set.reps
        }
    }
}
