import SwiftUI

public nonisolated enum DesignSystem {
    // MARK: - Colors

    public nonisolated enum Colors {
        // Accent Color
        public static let primary = Color(hexLight: "#B76E5A", hexDark: "#B76E5A")
        public static let primaryDark = Color(hexLight: "#9F5A47", hexDark: "#9F5A47")
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
        public static let info = Color(hexLight: "#5A8AB7", hexDark: "#ABCCE8")
        /// 全屏遮罩背景（如图片查看器）
        public static let overlayDark = Color(hexLight: "#000000", hexDark: "#000000")

        // Widget Gallery preview surfaces
        public static let widgetGalleryBgStart = Color(hexLight: "#FBF6EE", hexDark: "#1C1B19")
        public static let widgetGalleryBgEnd = Color(hexLight: "#F1E4D3", hexDark: "#0E0C0A")
        public static let widgetGalleryStageStart = Color(hexLight: "#FBF6EE", hexDark: "#2A2018")
        public static let widgetGalleryStageMid = Color(hexLight: "#F0E0C9", hexDark: "#1F1812")
        public static let widgetGalleryStageEnd = Color(hexLight: "#E8D4B2", hexDark: "#2A1F17")
        public static let widgetGalleryLockStart = Color(hexLight: "#3A4A78", hexDark: "#3A4A78")
        public static let widgetGalleryLockMid = Color(hexLight: "#1F2A4A", hexDark: "#1F2A4A")
        public static let widgetGalleryLockEnd = Color(hexLight: "#0A0E1F", hexDark: "#0A0E1F")
        public static let widgetGalleryDuskStart = Color(hexLight: "#FFD8B0", hexDark: "#FFD8B0")
        public static let widgetGalleryDuskMid = Color(hexLight: "#E89A85", hexDark: "#E89A85")
        public static let widgetGalleryDuskEnd = Color(hexLight: "#3A1D18", hexDark: "#3A1D18")
        public static let widgetGalleryPhotoSky = Color(hexLight: "#F5C5B0", hexDark: "#F5C5B0")
        public static let widgetGalleryPhotoSun = Color(hexLight: "#FFF3D7", hexDark: "#FFF3D7")
        public static let widgetGalleryPhotoHill = Color(hexLight: "#8B4A3F", hexDark: "#8B4A3F")
        public static let widgetGalleryPhotoHillDeep = Color(hexLight: "#5C2E28", hexDark: "#5C2E28")
    }

    // MARK: - Typography

    public nonisolated enum Typography {
        public static let title1 = Font.system(size: 28, weight: .bold, design: .default)
        public static let title2 = Font.system(size: 22, weight: .bold, design: .default)
        public static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        public static let body = Font.system(size: 16, weight: .regular, design: .default)
        public static let caption = Font.system(size: 14, weight: .medium, design: .default)
        public static let small = Font.system(size: 11, weight: .medium, design: .default)
        public static let display = Font.system(size: 48, weight: .bold, design: .default)
        public static let widgetTiny = Font.system(size: 9, weight: .medium, design: .default)
        public static let widgetTinyBold = Font.system(size: 9, weight: .bold, design: .default)
        public static let widgetMeta = Font.system(size: 10, weight: .medium, design: .default)
        public static let widgetMetaBold = Font.system(size: 10, weight: .bold, design: .default)
        public static let widgetBody = Font.system(size: 12, weight: .medium, design: .default)
        public static let widgetBodyBold = Font.system(size: 12, weight: .bold, design: .default)
        public static let widgetTitle = Font.system(size: 16, weight: .heavy, design: .default)
        public static let widgetTitleLarge = Font.system(size: 18, weight: .heavy, design: .default)
        public static let widgetMetric = Font.system(size: 30, weight: .heavy, design: .default)
        public static let widgetCountdown = Font.system(size: 42, weight: .heavy, design: .default)
    }

    // MARK: - Radius

    public nonisolated enum Radius {
        public static let card: CGFloat = 20
        public static let smallCard: CGFloat = 14
        public static let input: CGFloat = 12
        public static let button: CGFloat = .infinity
        public static let tag: CGFloat = 8
        /// 柱状图条、迷你进度条、热力图图例色块等细圆角
        public static let chartBar: CGFloat = 2
    }

    // MARK: - Spacing

    public nonisolated enum Spacing {
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
        /// 紧凑卡片列表行上下内边距（如关系健康度卡片）
        public static let listRowVertical: CGFloat = 14
        /// 卡片组内各项间距（比 block 更紧凑）
        public static let blockTight: CGFloat = 10
        /// 徽章水平内边距
        public static let badgePaddingH: CGFloat = 10
        /// 极小元素（子标签内双行）内部间距
        public static let insetXS: CGFloat = 2
        /// 小 badge 竖向内边距（细胶囊形徽章）
        public static let insetTight: CGFloat = 3
        /// 紧凑 badge 竖向内边距（档位选择等中等徽章）
        public static let insetSmall: CGFloat = 5
        /// 图标 + 文本并排行间距（推理卡片、时间轴行）
        public static let contentRowSpacing: CGFloat = 14
    }

    // MARK: - Layout（常用固定尺寸，避免视图内魔法数）

    public nonisolated enum Layout {
        public static let statisticsBarChartHeight: CGFloat = 160
        public static let rankBadgeSize: CGFloat = 28
        /// 列表行左侧头像、事件封面等缩略图
        public static let avatarM: CGFloat = 56
        /// 首页区块右上角紧凑操作按钮高度
        public static let homeInlineActionHeight: CGFloat = 40
        /// 首页区块右上角紧凑操作按钮图标底块尺寸
        public static let homeInlineActionIconSize: CGFloat = 24
        @MainActor
        public static var homeLedgerCardWidth: CGFloat {
            UIScreen.main.bounds.width - (DesignSystem.Spacing.pageHorizontal * 2) - DesignSystem.Spacing.stackTight
        }

        public static let circleAnalysisCardWidth: CGFloat = 140
        /// 联系人详情时间轴右侧金额/状态锚点宽度
        public static let timelineMetaWidth: CGFloat = 112
        public static let heroDecorationDiameter: CGFloat = 128
        public static let heroDecorationBlur: CGFloat = 20
        public static let heroDecorationOffset: CGFloat = 80
        public static let heatmapLegendSwatchWidth: CGFloat = 14
        public static let heatmapLegendSwatchHeight: CGFloat = 8
        /// 导入导出预览页底部主操作按钮宽度
        public static let selectionPreviewActionWidth: CGFloat = 220
        /// 关系健康度状态圆点直径
        public static let healthDotSize: CGFloat = 12
        /// 关系健康度徽章内小圆点直径
        public static let healthBadgeDotSize: CGFloat = 8
        /// 关系健康度圆点描边宽度
        public static let healthDotStrokeWidth: CGFloat = 2
        /// 智能回礼卡片图标背景块边长
        public static let smartGiftIconSize: CGFloat = 36
        /// 智能回礼时间轴金色圆点直径
        public static let timelineDotSize: CGFloat = 10
        /// 时间轴竖向连接线宽度（及档位节点描边宽度）
        public static let timelineConnectorWidth: CGFloat = 1.5
        /// 时间轴连接线最小高度
        public static let timelineConnectorMinHeight: CGFloat = 32
        /// 智能回礼推理卡片图标背景框边长
        public static let reasoningIconSize: CGFloat = 40
        /// 档位选择器轨道高度
        public static let tierTrackHeight: CGFloat = 2
        /// 档位选中节点直径
        public static let tierNodeSizeSelected: CGFloat = 22
        /// 档位未选中节点直径
        public static let tierNodeSizeDefault: CGFloat = 10
    }

    // MARK: - Effects

    public nonisolated enum Effects {
        public static let selectedFillOpacity: CGFloat = 0.1
        public static let selectedShadowOpacity: CGFloat = 0.12
        public static let disabledOpacity: CGFloat = 0.6
        public static let selectedShadowRadius: CGFloat = 4
        public static let selectedShadowYOffset: CGFloat = 2
    }
}

// MARK: - Component Styles

/// Primary Button Style
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

/// Secondary Button Style
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

/// Ghost Button Style
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

/// Standard Text Field Style
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
    nonisolated init(hexLight: String, hexDark: String) {
        self.init(UIColor { traitCollection in
            let isDark = traitCollection.userInterfaceStyle == .dark
            return UIColor(hex: isDark ? hexDark : hexLight)
        })
    }
}

extension UIColor {
    convenience nonisolated init(hex: String) {
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
