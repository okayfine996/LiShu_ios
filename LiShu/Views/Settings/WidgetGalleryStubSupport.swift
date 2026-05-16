import SwiftUI

// MARK: - Widget preview stubs (gallery-only, no widget extension dependency)

enum GallerySmallVariant { case reminder, countdown, financial }
enum GalleryMediumVariant { case reminder, event, financial }

func galleryKindColor(_ kind: ReminderKind) -> Color {
    switch kind {
    case .event: DesignSystem.Colors.primary
    case .birthday: DesignSystem.Colors.accentGold
    case .pendingReturn: DesignSystem.Colors.primaryDark
    }
}

func galleryKindName(_ kind: ReminderKind) -> String {
    switch kind {
    case .event: String(localized: "widget.kind.event")
    case .birthday: String(localized: "widget.reminder.birthday")
    case .pendingReturn: String(localized: "widget.kind.pendingReturn")
    }
}

func chineseYear(_ gregorianYear: Int) -> String {
    let stems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    let branches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    return "\(stems[(gregorianYear - 4) % 10])\(branches[(gregorianYear - 4) % 12])年"
}

struct GalleryMark: View {
    var size: CGFloat = 14
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primaryDark],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Text("礼").font(DesignSystem.Typography.widgetTinyBold).foregroundStyle(DesignSystem.Colors.textOnPrimary)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

struct GalleryWidgetBg: View {
    @Environment(\.colorScheme) private var cs
    var body: some View {
        if cs == .dark {
            LinearGradient(
                colors: [DesignSystem.Colors.widgetGalleryBgStart, DesignSystem.Colors.widgetGalleryBgEnd],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [DesignSystem.Colors.widgetGalleryBgStart, DesignSystem.Colors.widgetGalleryBgEnd],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}

#Preview("Widget Gallery Stub Support") {
    VStack(spacing: 12) {
        GalleryMark(size: 32)
        GalleryWidgetBg()
            .frame(width: 158, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    .padding()
}
