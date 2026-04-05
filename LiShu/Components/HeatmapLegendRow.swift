import SwiftUI

/// 人情热力图颜色条与说明（统计页、热力详情共用）。
struct HeatmapLegendRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.inlineTight) {
            HStack(spacing: DesignSystem.Spacing.dense) {
                ForEach(Array([0.12, 0.45, 0.8].enumerated()), id: \.offset) { _, opacity in
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.chartBar)
                        .fill(DesignSystem.Colors.primary.opacity(opacity))
                        .frame(
                            width: DesignSystem.Layout.heatmapLegendSwatchWidth,
                            height: DesignSystem.Layout.heatmapLegendSwatchHeight
                        )
                }
            }
            Text(String(localized: "statistics.heatmap.legend"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    HeatmapLegendRow()
        .padding()
}
