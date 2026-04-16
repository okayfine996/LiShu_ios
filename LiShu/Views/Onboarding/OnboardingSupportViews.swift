import SwiftUI

struct OnboardingSkipButton: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(String(localized: "onboarding.skip"), action: action)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.trailing, 20)
                .padding(.top, 8)
        }
    }
}

struct OnboardingIllustrationPage<Illustration: View>: View {
    @ViewBuilder let illustration: Illustration
    let spacingAfterIllustration: CGFloat
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            illustration

            Spacer().frame(height: spacingAfterIllustration)

            VStack(spacing: 12) {
                Text(title)
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }
}
