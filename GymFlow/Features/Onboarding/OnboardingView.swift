//
//  OnboardingView.swift
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

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                        .padding(.top, 48)

                    Text("onboarding.title")
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 16) {
                        bulletRow(icon: "plus.circle.fill", text: "onboarding.bullet.1")
                        bulletRow(icon: "timer", text: "onboarding.bullet.2")
                        bulletRow(icon: "trophy.fill", text: "onboarding.bullet.3")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }

            Button {
                onComplete()
            } label: {
                Text("onboarding.start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .padding(.top, 8)
            .accessibilityIdentifier("onboarding.start")
            .background(.background)
        }
    }

    @ViewBuilder
    private func bulletRow(icon: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
