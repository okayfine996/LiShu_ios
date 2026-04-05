import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(AppSettings.self) private var settings

    private enum AppColorScheme: String, CaseIterable {
        case light
        case dark
        case system

        var icon: String {
            switch self {
            case .light: "sun.max.fill"
            case .dark: "moon.fill"
            case .system: "iphone"
            }
        }

        var title: String {
            switch self {
            case .light: String(localized: "settings.appearance.light")
            case .dark: String(localized: "settings.appearance.dark")
            case .system: String(localized: "settings.appearance.system")
            }
        }

        var subtitle: String {
            switch self {
            case .light: String(localized: "settings.appearance.light.desc")
            case .dark: String(localized: "settings.appearance.dark.desc")
            case .system: String(localized: "settings.appearance.system.desc")
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            settings.colorScheme = scheme.rawValue
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: scheme.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(DesignSystem.Colors.primary)
                                .frame(width: 36, height: 36)
                                .background(DesignSystem.Colors.bgIconSubtle)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(scheme.title)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                                Text(scheme.subtitle)
                                    .font(DesignSystem.Typography.small)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }

                            Spacer()

                            if settings.colorScheme == scheme.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(DesignSystem.Colors.primary)
                            } else {
                                Circle()
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(16)
                        .background(
                            settings.colorScheme == scheme.rawValue
                                ? DesignSystem.Colors.bgCard
                                : DesignSystem.Colors.bgCard.opacity(0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                                .stroke(
                                    settings.colorScheme == scheme.rawValue
                                        ? DesignSystem.Colors.primary.opacity(0.3)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "settings.appearance"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
    .environment(AppSettings.shared)
}
