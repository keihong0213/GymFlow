import SwiftUI
import GymFlowCore

struct SessionExerciseSection: View {
    @Environment(SettingsStore.self) private var settings

    let section: SessionCoordinator.SessionExercise
    let locale: Locale
    let localizer: ExerciseLocalizer

    private var unit: WeightUnit { settings.units }
    let onLogSet: (Double, Int) -> Void
    let onDeleteSet: (UUID) -> Void

    @State private var weightInput: Double = 0
    @State private var repsInput: Int = 0
    @State private var seededDefaults = false
    @FocusState private var focus: Field?

    enum Field { case weight, reps }

    var body: some View {
        Section {
            ForEach(section.sets) { set in
                setRow(set)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDeleteSet(set.id)
                        } label: {
                            Label("common.delete", systemImage: "trash")
                        }
                    }
            }
            inputRow
        } header: {
            VStack(alignment: .leading, spacing: 4) {
                Text(localizer.displayName(for: section.exercise, locale: locale))
                    .font(.headline)
                    .textCase(nil)
                if let previousSummary {
                    Text(previousSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        .onAppear(perform: seedDefaultsIfNeeded)
    }

    @ViewBuilder
    private func setRow(_ set: SetEntry) -> some View {
        HStack(spacing: 12) {
            Text("\(set.setNumber)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(width: 24, alignment: .leading)
                .foregroundStyle(.secondary)
            Text(weightString(for: set.weightKg))
                .font(.body.weight(.medium))
                .monospacedDigit()
            Text("×")
                .foregroundStyle(.secondary)
            Text("\(set.reps)")
                .font(.body.weight(.medium))
                .monospacedDigit()
            Spacer()
        }
        .contentShape(Rectangle())
    }

    private var nextSetNumber: Int {
        (section.sets.map(\.setNumber).max() ?? 0) + 1
    }

    @ViewBuilder
    private var inputRow: some View {
        HStack(spacing: 10) {
            Text("\(nextSetNumber)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(width: 24, alignment: .leading)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                TextField("0", value: $weightInput, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focus, equals: .weight)
                    .frame(minWidth: 50)
                Text(unit.rawValue)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemFill))
            )

            Text("×").foregroundStyle(.secondary)

            TextField("0", value: $repsInput, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .focused($focus, equals: .reps)
                .frame(minWidth: 44)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemFill))
                )

            Spacer(minLength: 4)

            Button {
                submit()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .tint(.accentColor)
            .disabled(repsInput <= 0)
        }
        .padding(.vertical, 4)
    }

    private func submit() {
        guard repsInput > 0 else { return }
        let kg = unit.toKg(weightInput)
        onLogSet(kg, repsInput)
        focus = nil
    }

    private func seedDefaultsIfNeeded() {
        guard !seededDefaults else { return }
        seededDefaults = true
        if let latest = section.sets.last {
            weightInput = unit.fromKg(latest.weightKg)
            repsInput = latest.reps
        } else if let previous = section.previousSets.first {
            weightInput = unit.fromKg(previous.weightKg)
            repsInput = previous.reps
        }
    }

    private func weightString(for kg: Double) -> String {
        let value = unit.fromKg(kg)
        let nf = NumberFormatter()
        nf.locale = locale
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        let num = nf.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(num) \(unit.rawValue)"
    }

    private var previousSummary: String? {
        guard !section.previousSets.isEmpty else { return nil }
        let joined = section.previousSets
            .prefix(4)
            .map { weightString(for: $0.weightKg) + " × \($0.reps)" }
            .joined(separator: "  ·  ")
        return joined
    }
}
