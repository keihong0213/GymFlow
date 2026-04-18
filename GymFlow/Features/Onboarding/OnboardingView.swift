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
