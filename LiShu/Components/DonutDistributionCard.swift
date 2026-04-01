import SwiftUI

/// 环形图 + 右侧列表的统计卡片，用于事件分布、人情构成等场景。
struct DonutDistributionCard<Rows: View>: View {
    let title: String
    var titleSystemImage: String? = nil
    /// 为 `false` 时标题由外层区段展示（与环形图内容分离）。
    var showsTitleHeader: Bool = true
    let emptyMessage: String
    let isEmpty: Bool
    let ringSegments: [DonutRingSegment]
    let centerTopLabel: String
    let centerMainText: String
    /// 人情构成等场景中心为大数字时使用 `true`，事件分布等场景为 `false`。
    var centerMainUsesLargeValueStyle: Bool = false
    /// 环形图外圈可点击跳转时传入（如事件分布点击进占比最高类型）。
    var donutNavigationRoute: AppRoute? = nil
    @ViewBuilder let rows: () -> Rows

    private let donutSize: CGFloat = 140
    private let strokeWidth: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showsTitleHeader {
                header
            }

            if isEmpty {
                Text(emptyMessage)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                HStack(alignment: .center, spacing: 24) {
                    Group {
                        if let route = donutNavigationRoute {
                            NavigationLink(value: route) {
                                donutRing
                            }
                            .buttonStyle(.plain)
                        } else {
                            donutRing
                        }
                    }
                    .frame(width: donutSize, height: donutSize)

                    VStack(alignment: .leading, spacing: 8) {
                        rows()
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            if let titleSystemImage {
                Image(systemName: titleSystemImage)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.primary)
            }
            Text(title)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }

    private var donutRing: some View {
        ZStack {
            Circle()
                .stroke(DesignSystem.Colors.primary.opacity(0.1), lineWidth: strokeWidth)

            ForEach(Array(ringSegments.enumerated()), id: \.offset) { _, segment in
                Circle()
                    .trim(from: segment.start, to: segment.end)
                    .stroke(
                        segment.color,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text(centerTopLabel)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Text(centerMainText)
                    .font(centerMainUsesLargeValueStyle ? DesignSystem.Typography.title3 : DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct DonutRingSegment {
    let start: CGFloat
    let end: CGFloat
    let color: Color
}

#Preview {
    DonutDistributionCard(
        title: "示例",
        emptyMessage: "暂无数据",
        isEmpty: false,
        ringSegments: [
            DonutRingSegment(start: 0, end: 0.6, color: DesignSystem.Colors.primary),
            DonutRingSegment(start: 0.6, end: 1, color: DesignSystem.Colors.primary.opacity(0.4)),
        ],
        centerTopLabel: "合计",
        centerMainText: "128",
        centerMainUsesLargeValueStyle: true
    ) {
        Text("列表占位")
            .font(DesignSystem.Typography.small)
    }
}
