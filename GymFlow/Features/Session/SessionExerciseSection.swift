import SwiftUI
import GymFlowCore

struct SessionExerciseSection: View {
    @Environment(SettingsStore.self) private var settings

    let section: SessionCoordinator.SessionExercise
    let locale: Locale
    let localizer: ExerciseLocalizer

    private var unit: WeightUnit { settings.units }
    let onLogSet: (Double, Int) -> Void
    let onLogCardioSet: (Int, Double?) -> Void
    let onDeleteSet: (UUID) -> Void
    let onEditSet: (SetEntry) -> Void

    @State private var weightInput: Double = 0
    @State private var repsInput: Int = 0
    @State private var minutesInput: Int = 0
    @State private var secondsInput: Int = 0
    @State private var distanceKmInput: Double = 0
    @State private var seededDefaults = false
    @FocusState private var focus: Field?

    enum Field { case weight, reps, minutes, seconds, distance }

    var body: some View {
        Section {
            ForEach(section.sets) { set in
                Button {
                    onEditSet(set)
                } label: {
                    setRow(set)
                }
                .buttonStyle(.plain)
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

    private var isBodyweight: Bool {
        section.exercise.category == .bodyweight
    }

    private var isCardio: Bool {
        section.exercise.category == .cardio
    }

    @ViewBuilder
    private func setRow(_ set: SetEntry) -> some View {
        HStack(spacing: 12) {
            Text("\(set.setNumber)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(minWidth: 24, alignment: .leading)
                .foregroundStyle(.secondary)
            if isCardio {
                Text(durationString(for: set.durationSec ?? 0))
                    .font(.body.weight(.medium))
                    .monospacedDigit()
                if let distance = set.distanceMeters, distance > 0 {
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(distanceString(meters: distance))
                        .font(.body.weight(.medium))
                        .monospacedDigit()
                }
            } else if isBodyweight {
                Text("\(set.reps)")
                    .font(.body.weight(.medium))
                    .monospacedDigit()
                Text("session.reps_unit")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text(weightString(for: set.weightKg))
                    .font(.body.weight(.medium))
                    .monospacedDigit()
                Text("×")
                    .foregroundStyle(.secondary)
                Text("\(set.reps)")
                    .font(.body.weight(.medium))
                    .monospacedDigit()
            }
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
                .frame(minWidth: 24, alignment: .leading)
                .foregroundStyle(.secondary)

            if isCardio {
                cardioInputs
            } else if isBodyweight {
                bodyweightInputs
            } else {
                strengthInputs
            }

            Spacer(minLength: 4)

            Button {
                submit()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .tint(.accentColor)
            .disabled(!canSubmit)
            .accessibilityLabel("a11y.log_set")
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var strengthInputs: some View {
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
    }

    @ViewBuilder
    private var bodyweightInputs: some View {
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
        Text("session.reps_unit")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var cardioInputs: some View {
        HStack(spacing: 2) {
            TextField("0", value: $minutesInput, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($focus, equals: .minutes)
                .frame(minWidth: 32)
            Text(":").foregroundStyle(.secondary)
            TextField("00", value: $secondsInput, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.leading)
                .focused($focus, equals: .seconds)
                .frame(minWidth: 32)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
        )

        HStack(spacing: 4) {
            TextField("0", value: $distanceKmInput, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($focus, equals: .distance)
                .frame(minWidth: 48)
            Text("session.distance_unit")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
        )
    }

    private var canSubmit: Bool {
        if isCardio {
            return (minutesInput * 60 + secondsInput) > 0
        }
        return repsInput > 0
    }

    private func submit() {
        if isCardio {
            let duration = minutesInput * 60 + secondsInput
            guard duration > 0 else { return }
            let distanceMeters = distanceKmInput > 0 ? distanceKmInput * 1000 : nil
            onLogCardioSet(duration, distanceMeters)
            focus = nil
            return
        }
        guard repsInput > 0 else { return }
        let kg = isBodyweight ? 0 : unit.toKg(weightInput)
        onLogSet(kg, repsInput)
        focus = nil
    }

    private func seedDefaultsIfNeeded() {
        guard !seededDefaults else { return }
        seededDefaults = true
        let source = section.sets.last ?? section.previousSets.first
        guard let source else { return }
        if isCardio {
            let total = source.durationSec ?? 0
            minutesInput = total / 60
            secondsInput = total % 60
            if let meters = source.distanceMeters, meters > 0 {
                distanceKmInput = meters / 1000
            }
        } else if isBodyweight {
            repsInput = source.reps
        } else {
            weightInput = unit.fromKg(source.weightKg)
            repsInput = source.reps
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
            .map { set -> String in
                if isCardio {
                    var parts = [durationString(for: set.durationSec ?? 0)]
                    if let meters = set.distanceMeters, meters > 0 {
                        parts.append(distanceString(meters: meters))
                    }
                    return parts.joined(separator: " · ")
                }
                if isBodyweight {
                    return "\(set.reps)"
                }
                return weightString(for: set.weightKg) + " × \(set.reps)"
            }
            .joined(separator: "  ·  ")
        return joined
    }

    private func durationString(for sec: Int) -> String {
        WorkoutFormatters.duration(fromSeconds: sec)
    }

    private func distanceString(meters: Double) -> String {
        WorkoutFormatters.distance(meters: meters, locale: locale)
    }
}
