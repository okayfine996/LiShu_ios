import SwiftUI

public enum DesignSystem {

    // MARK: - Colors
    public struct Colors {
        // Accent Color
        public static let primary = Color(hexLight: "#B76E5A", hexDark: "#B76E5A")
        public static let accentGold = Color(hexLight: "#C5A065", hexDark: "#C5A065")

        // Backgrounds
        public static let bgPage = Color(hexLight: "#F5EFE6", hexDark: "#1C1B19")
        public static let bgCard = Color(hexLight: "#E8DDD1", hexDark: "#262422") // Surface
        public static let bgInput = Color(hexLight: "#ECE3D7", hexDark: "#2E2B29") // Subtle
        public static let bgTag = Color(hexLight: "#D9CFC4", hexDark: "#363330")
        public static let bgSurface = Color(hexLight: "#FFFFFF", hexDark: "#2A2220")
        public static let bgIconSubtle = Color(hexLight: "#F5F0EB", hexDark: "#2E2B29")

        // Pro Gradient
        public static let proGradientStart = Color(hexLight: "#FFFCF5", hexDark: "#2A2220")
        public static let proGradientEnd = Color(hexLight: "#FFF7E6", hexDark: "#3A2E25")

        // Border & Separator
        public static let border = Color(hexLight: "#D9CFC4", hexDark: "#3D3935")
        public static let separator = border

        // Text
        public static let textPrimary = Color(hexLight: "#2C2C2C", hexDark: "#E6E1DC")
        public static let textSecondary = Color(hexLight: "#7A746E", hexDark: "#ABA59F")
        public static let textTertiary = Color(hexLight: "#ABA59F", hexDark: "#7A746E")
        public static let textOnPrimary = Color.white

        // Semantic
        public static let income = accentGold
        public static let destructive = Color(hexLight: "#E53935", hexDark: "#EF5350")
        /// 全屏遮罩背景（如图片查看器）
        public static let overlayDark = Color(hexLight: "#000000", hexDark: "#000000")
    }

    // MARK: - Typography
    public struct Typography {
        public static let title1 = Font.system(size: 28, weight: .bold, design: .default)
        public static let title2 = Font.system(size: 22, weight: .bold, design: .default)
        public static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        public static let body = Font.system(size: 16, weight: .regular, design: .default)
        public static let caption = Font.system(size: 14, weight: .medium, design: .default)
        public static let small = Font.system(size: 11, weight: .medium, design: .default)
        public static let display = Font.system(size: 48, weight: .bold, design: .default)
    }

    // MARK: - Radius
    public struct Radius {
        public static let card: CGFloat = 20
        public static let smallCard: CGFloat = 14
        public static let input: CGFloat = 12
        public static let button: CGFloat = .infinity
        public static let tag: CGFloat = 8
        /// 柱状图条、迷你进度条、热力图图例色块等细圆角
        public static let chartBar: CGFloat = 2
    }

    // MARK: - Spacing
    public struct Spacing {
        public static let section: CGFloat = 28
        public static let block: CGFloat = 12
        /// 页面水平内边距（与导航内容区对齐）
        public static let pageHorizontal: CGFloat = 16
        /// 纵向大区块间距（如统计页各模块之间）
        public static let stackLoose: CGFloat = 20
        /// Scroll 内容底部留白
        public static let scrollBottom: CGFloat = 24
        /// 图标与文字、紧凑行内间距
        public static let inlineTight: CGFloat = 8
        /// 热力图格内等更密间距
        public static let dense: CGFloat = 6
        /// 两行标题/标签之间
        public static let stackTight: CGFloat = 4
        /// 常规卡片内边距（环形图、柱状图等）
        public static let cardPadding: CGFloat = 20
        /// 首屏总览等强调卡片内边距
        public static let heroCardPadding: CGFloat = 24
        /// 横向滑动小卡、紧凑信息块内边距
        public static let cardPaddingSmall: CGFloat = 16
    }

    // MARK: - Layout（常用固定尺寸，避免视图内魔法数）
    public struct Layout {
        public static let statisticsBarChartHeight: CGFloat = 160
        public static let rankBadgeSize: CGFloat = 28
        public static let avatarM: CGFloat = 48
        public static let circleAnalysisCardWidth: CGFloat = 140
        public static let heroDecorationDiameter: CGFloat = 128
        public static let heroDecorationBlur: CGFloat = 20
        public static let heroDecorationOffset: CGFloat = 80
        public static let heatmapLegendSwatchWidth: CGFloat = 14
        public static let heatmapLegendSwatchHeight: CGFloat = 8
    }

    // MARK: - Effects
    public struct Effects {
        public static let selectedFillOpacity: CGFloat = 0.1
        public static let selectedShadowOpacity: CGFloat = 0.12
        public static let disabledOpacity: CGFloat = 0.6
        public static let selectedShadowRadius: CGFloat = 4
        public static let selectedShadowYOffset: CGFloat = 2
    }
}

// MARK: - Component Styles

// Primary Button Style
public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.primary)
            .clipShape(Capsule())
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.3) : DesignSystem.Colors.primary.opacity(0.2),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Secondary Button Style
public struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? DesignSystem.Colors.bgTag : DesignSystem.Colors.bgCard)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Ghost Button Style
public struct GhostButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? DesignSystem.Colors.textSecondary.opacity(0.1) : Color.clear)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Standard Text Field Style
public struct StandardTextFieldStyle: TextFieldStyle {
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .background(DesignSystem.Colors.bgSurface)
            .cornerRadius(DesignSystem.Radius.input)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
    }
}

// MARK: - Color Hex Extensions
extension Color {
    init(hexLight: String, hexDark: String) {
        self.init(UIColor { traitCollection in
            let isDark = traitCollection.userInterfaceStyle == .dark
            return UIColor(hex: isDark ? hexDark : hexLight)
        })
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
