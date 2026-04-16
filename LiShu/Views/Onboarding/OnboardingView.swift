import SwiftUI

struct OnboardingView: View {
    @Environment(AppSettings.self) private var settings
    @State private var currentPage = 0

    private let totalPages = 4

    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            OnboardingContentView(
                currentPage: $currentPage,
                totalPages: totalPages,
                onSkip: completeOnboarding,
                onAdvance: advance,
                onComplete: completeOnboarding
            )
        }
    }

    private func completeOnboarding() {
        settings.hasSeenOnboarding = true
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage += 1
        }
    }
}
