//
//  RestTimerPill.swift
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

struct RestTimerPill: View {
    let remaining: TimeInterval
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .accessibilityHidden(true)
            Text(timeString)
                .font(.body.weight(.semibold).monospacedDigit())
                .accessibilityLabel("a11y.rest_remaining")
                .accessibilityValue(Text("a11y.seconds \(Int(remaining.rounded(.up)))"))
            Spacer()
            Button(role: .cancel) {
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("a11y.cancel_rest")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule().fill(Color.accentColor.opacity(0.15))
        )
        .overlay(
            Capsule().stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
        )
        .foregroundStyle(Color.accentColor)
    }

    private var timeString: String {
        let t = Int(remaining.rounded(.up))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
