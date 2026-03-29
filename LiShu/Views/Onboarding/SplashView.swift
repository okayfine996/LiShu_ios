import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("礼")
                    .font(.system(size: 44, weight: .bold, design: .serif))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: 80, height: 80)
                    .background(DesignSystem.Colors.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))

                Text(String(localized: "app.name"))
                    .font(DesignSystem.Typography.title1)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(String(localized: "app.slogan"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    SplashView()
}
