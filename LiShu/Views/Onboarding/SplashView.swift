import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .blendMode(.multiply)

                Text(String(localized: "app.name"))
                    .font(DesignSystem.Typography.title1)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .tracking(12)

                Text(String(localized: "app.slogan"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.accentGold)
                    .tracking(2)
            }
        }
    }
}

#Preview {
    SplashView()
}
