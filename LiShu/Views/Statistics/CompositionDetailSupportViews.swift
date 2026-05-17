import SwiftUI

struct CompositionMiniBarChart: View {
    let distribution: [Int]
    let color: Color

    private let chartHeight: CGFloat = 60

    var body: some View {
        let maxCount = max(distribution.max() ?? 1, 1)

        HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<12, id: \.self) { index in
                let count = distribution[index]

                VStack(spacing: 4) {
                    Spacer(minLength: 0)
                    if count > 0 {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(count == maxCount ? 1.0 : 0.4))
                            .frame(height: max(chartHeight * CGFloat(count) / CGFloat(maxCount), 4))
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DesignSystem.Colors.primary.opacity(0.08))
                            .frame(height: 4)
                    }

                    Text("\(index + 1)")
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: chartHeight + 18)
    }
}

struct CompositionDonutSegment {
    let start: CGFloat
    let end: CGFloat
    let index: Int
}

enum CompositionChartSupport {
    static func donutSegments(for percentages: [Double]) -> [CompositionDonutSegment] {
        var segments: [CompositionDonutSegment] = []
        var current: CGFloat = 0

        for (index, percentage) in percentages.enumerated() {
            let end = current + CGFloat(percentage)
            segments.append(
                CompositionDonutSegment(start: current, end: min(end, 1.0), index: index)
            )
            current = end
        }

        return segments
    }

    static func color(for index: Int) -> Color {
        switch index {
        case 0:
            DesignSystem.Colors.primary
        case 1:
            DesignSystem.Colors.primary.opacity(0.55)
        case 2:
            DesignSystem.Colors.textTertiary.opacity(0.5)
        default:
            DesignSystem.Colors.textPrimary.opacity(0.7)
        }
    }
}
