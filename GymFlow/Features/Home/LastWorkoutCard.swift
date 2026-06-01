//
//  LastWorkoutCard.swift
//  Kintore (internal module name: GymFlow)
//
//  Copyright © 2026 Keihong.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import SwiftUI
import GymFlowCore

struct LastWorkoutCard: View {
    @Environment(SettingsStore.self) private var settings

    let summary: WorkoutSummary
    let locale: Locale

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("home.last_workout")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(relativeDateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                metric(value: "\(summary.exerciseCount)", label: "home.exercises")
                divider
                metric(value: "\(summary.setCount)", label: "home.sets")
                divider
                metric(value: volumeString, label: "home.volume")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 1, height: 28)
    }

    @ViewBuilder
    private func metric(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var volumeString: String {
        let formatter = WeightFormatter(unit: settings.units, locale: locale)
        let full = formatter.format(kg: summary.totalVolumeKg)
        return full
    }

    private var relativeDateString: String {
        let f = RelativeDateTimeFormatter()
        f.locale = locale
        f.unitsStyle = .full
        return f.localizedString(for: summary.startedAt, relativeTo: .now)
    }
}
