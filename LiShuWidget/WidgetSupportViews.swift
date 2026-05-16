import SwiftUI

// MARK: - Deep Link URL helpers

extension URL {
    static let liShuHome: URL = {
        var c = URLComponents(); c.scheme = "lishu"; c.host = "home"
        return c.url ?? URL(fileURLWithPath: "/")
    }()

    static let liShuAddRecord: URL = {
        var c = URLComponents(); c.scheme = "lishu"; c.host = "add-record"
        return c.url ?? URL(fileURLWithPath: "/")
    }()
}

// MARK: - Color helpers (mirrors DesignSystem — widget extension cannot access main app target)

private extension Color {
    init(hexLight: String, hexDark: String) {
        self.init(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hex: hexDark) : UIColor(hex: hexLight) })
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255, green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Palette

// Widget extension cannot access the main app's DesignSystem, so colors are defined here
// using the same Color(hexLight:hexDark:) pattern. ARGB (8-digit) hex encodes alpha.
// Keep in sync with DesignSystem.Colors when brand values change.
enum WidgetPalette {
    // Brand (same in both modes)
    static let accent     = Color(hexLight: "#B76E5A", hexDark: "#B76E5A") // DesignSystem.Colors.primary
    static let accentDark = Color(hexLight: "#9F5A47", hexDark: "#9F5A47") // DesignSystem.Colors.primaryDark
    static let gold       = Color(hexLight: "#C5A065", hexDark: "#C5A065") // DesignSystem.Colors.accentGold

    // Adaptive text (ARGB dark values = parchment #F5EFE6 at given alpha)
    static let textPrimary   = Color(hexLight: "#2C2C2C", hexDark: "#EBF5EFE6") // ×0.92α
    static let textSecondary = Color(hexLight: "#7A746E", hexDark: "#8CF5EFE6") // ×0.55α
    static let textTertiary  = Color(hexLight: "#ABA59F", hexDark: "#73F5EFE6") // ×0.45α

    // Adaptive background gradient stops
    static let bgTop    = Color(hexLight: "#FBF6EE", hexDark: "#1C1B19")
    static let bgBottom = Color(hexLight: "#F1E5D4", hexDark: "#0E0C0A")

    // Adaptive structural (ARGB — alpha baked in; brown #78593D = rgb(0.47,0.35,0.24))
    static let divider       = Color(hexLight: "#1F78593D", hexDark: "#14FFFFFF") // 12% / 8%
    static let dividerStrong = Color(hexLight: "#2678593D", hexDark: "#1AFFFFFF") // 15% / 10%
    static let barTrack      = Color(hexLight: "#1A78593D", hexDark: "#14FFFFFF") // 10% / 8%
    static let badgeBg       = Color(hexLight: "#24B76E5A", hexDark: "#47B76E5A") // accent 14% / 28%
    static let accentSubtle  = Color(hexLight: "#1AB76E5A", hexDark: "#26B76E5A") // accent 10% / 15%
    static let heroAccentFill = Color(hexLight: "#1AB76E5A", hexDark: "#38B76E5A") // accent 10% / 22%
    static let heroGoldFill   = Color(hexLight: "#1AC5A065", hexDark: "#29C5A065") // gold 10% / 16%
}

func kindColor(_ kind: ReminderKind) -> Color {
    switch kind {
    case .event: WidgetPalette.accent
    case .birthday: WidgetPalette.gold
    case .pendingReturn: WidgetPalette.accentDark
    }
}

// Reminder row date-badge fill — adaptive per kind (ARGB: 18% light / 30% dark)
func kindBadgeFill(_ kind: ReminderKind) -> Color {
    switch kind {
    case .event:         Color(hexLight: "#2EB76E5A", hexDark: "#4DB76E5A")
    case .birthday:      Color(hexLight: "#2EC5A065", hexDark: "#4DC5A065")
    case .pendingReturn: Color(hexLight: "#2E9F5A47", hexDark: "#4D9F5A47")
    }
}

func kindName(_ kind: ReminderKind) -> String {
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

// MARK: - Background

struct WidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [WidgetPalette.bgTop, WidgetPalette.bgBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Shared Sub-components

struct LiShuMark: View {
    var size: CGFloat = 14

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WidgetPalette.accent, WidgetPalette.accentDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text("礼")
                .font(.system(size: size * 0.62, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

struct WidgetHeader: View {
    let count: Int
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            LiShuMark(size: compact ? 14 : 16)
            Text(String(localized: "widget.displayName"))
                .font(.system(size: compact ? 11 : 12, weight: .bold))
                .foregroundStyle(WidgetPalette.textPrimary)
            Spacer(minLength: 0)
            if count > 0 {
                Text(String(format: String(localized: "widget.reminderCount"), count))
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(WidgetPalette.badgeBg))
                    .foregroundStyle(WidgetPalette.textPrimary)
            }
        }
    }
}

struct WidgetReminderRow: View {
    let item: WidgetReminderItem
    var compact: Bool = false

    private var dot: Color {
        kindColor(item.kind)
    }

    var body: some View {
        HStack(spacing: compact ? 6 : 8) {
            Circle()
                .fill(dot)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: compact ? 11 : 12, weight: .semibold))
                    .foregroundStyle(WidgetPalette.textPrimary)
                    .lineLimit(1)
                if !compact {
                    Text(item.subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(WidgetPalette.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Text(item.dateLabel)
                .font(.system(size: compact ? 10 : 10.5, weight: .bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(kindBadgeFill(item.kind)))
                .foregroundStyle(dot)
                .fixedSize()
        }
    }
}

struct WidgetEmptyState: View {
    var body: some View {
        HStack {
            Spacer()
            Label(String(localized: "widget.noReminders"), systemImage: "calendar.badge.checkmark")
                .font(.caption)
                .foregroundStyle(WidgetPalette.textTertiary)
            Spacer()
        }
    }
}

#Preview("Widget Support") {
    VStack(alignment: .leading, spacing: 16) {
        WidgetHeader(count: 3)
        WidgetReminderRow(item: WidgetReminderItem(
            id: "support-preview",
            title: "王芳",
            subtitle: String(localized: "widget.reminder.birthday"),
            dateLabel: String(localized: "widget.reminder.tomorrow"),
            urgencyDaysFromNow: 1,
            kind: .birthday,
            deepLinkURL: .liShuHome,
            eventDateLabel: "5月16日"
        ))
        WidgetEmptyState()
    }
    .padding(16)
    .background(WidgetBackground())
}
