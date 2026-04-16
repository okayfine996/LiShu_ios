import SwiftUI

struct CompositionRecordTypesContent: View {
    let viewModel: RecordTypeCompositionViewModel

    var body: some View {
        CompositionDonutCard(
            totalCount: viewModel.totalCount,
            legendItems: viewModel.items.enumerated().map {
                .init(title: $0.element.type.displayName, percentage: $0.element.percentage, colorIndex: $0.offset)
            },
            segments: CompositionChartSupport.donutSegments(for: viewModel.items.map(\.percentage))
        )

        CompositionDetailCardList(
            title: String(localized: "recordTypeComposition.detailSection"),
            cards: viewModel.items.enumerated().map { index, item in
                .init(
                    title: item.type.displayName,
                    ratioText: String(
                        format: String(localized: "recordTypeComposition.ratio"),
                        item.percentage * 100
                    ),
                    amountTitle: item.isMonetaryAggregate
                        ? String(localized: "recordTypeComposition.totalAmount")
                        : nil,
                    amountValue: item.isMonetaryAggregate ? viewModel.formatAmount(item.aggregateValue) : nil,
                    countText: viewModel.formatCount(Double(item.count)),
                    distribution: item.monthlyDistribution,
                    colorIndex: index
                )
            }
        )
    }
}

struct CompositionEventTypesContent: View {
    let viewModel: EventTypeCompositionViewModel

    var body: some View {
        CompositionDonutCard(
            totalCount: viewModel.totalCount,
            legendItems: viewModel.items.enumerated().map {
                .init(title: $0.element.eventType.displayName, percentage: $0.element.percentage, colorIndex: $0.offset)
            },
            segments: CompositionChartSupport.donutSegments(for: viewModel.items.map(\.percentage))
        )

        CompositionDetailCardList(
            title: String(localized: "recordTypeComposition.detailSection"),
            cards: viewModel.items.enumerated().map { index, item in
                .init(
                    title: item.eventType.displayName,
                    ratioText: String(
                        format: String(localized: "recordTypeComposition.ratio"),
                        item.percentage * 100
                    ),
                    amountTitle: item.isMonetaryAggregate
                        ? String(localized: "recordTypeComposition.totalAmount")
                        : nil,
                    amountValue: item.isMonetaryAggregate ? viewModel.formatAmount(item.aggregateValue) : nil,
                    countText: viewModel.formatCount(Double(item.count)),
                    distribution: item.monthlyDistribution,
                    colorIndex: index
                )
            }
        )
    }
}

private struct CompositionDonutCard: View {
    let totalCount: Int
    let legendItems: [CompositionLegendItem]
    let segments: [CompositionDonutSegment]

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.primary.opacity(0.1), lineWidth: 20)

                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(
                            CompositionChartSupport.color(for: segment.index),
                            style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                }

                VStack(spacing: 4) {
                    Text(String(localized: "recordTypeComposition.yearTotal"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                    Text("\(totalCount)")
                        .font(DesignSystem.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }
            .frame(width: 180, height: 180)
            .padding(.top, 8)

            CompositionLegendGrid(items: legendItems)
        }
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct CompositionLegendGrid: View {
    let items: [CompositionLegendItem]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items) { item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(CompositionChartSupport.color(for: item.colorIndex))
                        .frame(width: 10, height: 10)
                    Text(item.title)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(String(format: "%.0f%%", item.percentage * 100))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Spacer()
                }
            }
        }
    }
}

private struct CompositionDetailCardList: View {
    let title: String
    let cards: [CompositionDetailCardModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ForEach(cards) { card in
                CompositionDetailCard(card: card)
            }
        }
    }
}

private struct CompositionDetailCard: View {
    let card: CompositionDetailCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(card.ratioText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let amountTitle = card.amountTitle, let amountValue = card.amountValue {
                        Text(amountTitle)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                        Text(amountValue)
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                    Text(card.countText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            CompositionMiniBarChart(
                distribution: card.distribution,
                color: CompositionChartSupport.color(for: card.colorIndex)
            )
        }
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct CompositionLegendItem: Identifiable {
    let id = UUID()
    let title: String
    let percentage: Double
    let colorIndex: Int
}

private struct CompositionDetailCardModel: Identifiable {
    let id = UUID()
    let title: String
    let ratioText: String
    let amountTitle: String?
    let amountValue: String?
    let countText: String
    let distribution: [Int]
    let colorIndex: Int
}
