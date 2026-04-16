import SwiftUI

struct OnboardingContentView: View {
    @Binding var currentPage: Int

    let totalPages: Int
    let onSkip: () -> Void
    let onAdvance: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if currentPage < totalPages - 1 {
                OnboardingSkipButton(action: onSkip)
            }

            TabView(selection: $currentPage) {
                OnboardingWelcomePage().tag(0)
                OnboardingFeaturesPage().tag(1)
                OnboardingValuePage().tag(2)
                OnboardingRelationshipPage().tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            OnboardingFooter(
                currentPage: currentPage,
                totalPages: totalPages,
                onAdvance: onAdvance,
                onComplete: onComplete
            )
        }
    }
}

private struct OnboardingFooter: View {
    let currentPage: Int
    let totalPages: Int
    let onAdvance: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(0 ..< totalPages, id: \.self) { index in
                    Circle()
                        .fill(
                            index == currentPage
                                ? DesignSystem.Colors.primary
                                : DesignSystem.Colors.textTertiary.opacity(0.3)
                        )
                        .frame(width: 8, height: 8)
                }
            }

            if currentPage == totalPages - 1 {
                Button(String(localized: "onboarding.start"), action: onComplete)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 32)
            } else {
                Button(action: onAdvance) {
                    Text(String(localized: "onboarding.next"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.bottom, 40)
    }
}
