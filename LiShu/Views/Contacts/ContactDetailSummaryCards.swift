import SwiftUI

struct ContactDetailSummaryCardsSection: View {
    let contact: Contact
    let viewModel: ContactDetailViewModel
    @Binding var currentCardPage: Int

    var body: some View {
        CarouselView(
            pageCount: 2,
            currentPage: $currentCardPage,
            indicatorPosition: .topTrailing
        ) { index in
            Group {
                if index == 0 {
                    ContactDetailAssetOverviewCard(contact: contact, viewModel: viewModel)
                } else {
                    ContactDetailRelationshipInsightCard(contact: contact, viewModel: viewModel)
                }
            }
        }
        .aspectRatio(1.5, contentMode: .fit)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .padding(.horizontal, 16)
    }
}

private struct ContactDetailAssetOverviewCard: View {
    let contact: Contact
    let viewModel: ContactDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "contact.detail.assetOverview"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(.trailing, DesignSystem.Spacing.cardPadding + DesignSystem.Spacing.section)
                .padding(.bottom, 20)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "contact.detail.netSurplus"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(viewModel.formatNetValue(contact.netValue))
                        .font(DesignSystem.Typography.title1)
                        .foregroundStyle(netValueColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(localized: "contact.detail.frequency"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(viewModel.pastYearInteractionCount)")
                            .font(DesignSystem.Typography.title1)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text(String(localized: "common.times"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .padding(.bottom, 20)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "contact.detail.composition"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    let typeCounts = viewModel.typeCounts
                    if !typeCounts.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(typeCounts.prefix(3)) { item in
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(DesignSystem.Colors.textTertiary)
                                        .frame(width: 4, height: 4)
                                    Text("\(item.type.displayName) \(item.count)")
                                        .font(DesignSystem.Typography.small)
                                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                                }
                            }
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(String(localized: "contact.detail.incomeExpense"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    ContactDetailAmountPair(
                        label: String(localized: "contact.detail.incomeShort"),
                        value: viewModel.formatAmount(contact.totalReceived)
                    )
                    ContactDetailAmountPair(
                        label: String(localized: "contact.detail.expenseShort"),
                        value: viewModel.formatAmount(contact.totalGiven)
                    )
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var netValueColor: Color {
        contact.netValue >= 0
            ? DesignSystem.Colors.accentGold
            : DesignSystem.Colors.primary
    }
}

private struct ContactDetailRelationshipInsightCard: View {
    let contact: Contact
    let viewModel: ContactDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "contact.detail.relationshipInsight"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(.trailing, DesignSystem.Spacing.cardPadding + DesignSystem.Spacing.section)
                .padding(.bottom, 20)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "contact.detail.activityRate"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(String(format: "%.1f%%", viewModel.yearlyActivityRate * 100))
                        .font(DesignSystem.Typography.title1)
                        .foregroundStyle(DesignSystem.Colors.primary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(DesignSystem.Colors.bgTag)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(DesignSystem.Colors.primary)
                                .frame(width: geo.size.width * viewModel.yearlyActivityRate, height: 6)
                        }
                    }
                    .frame(height: 6)
                    .frame(maxWidth: 120)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(localized: "contact.detail.balanceIndex"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(viewModel.balanceLevelText(viewModel.balanceLevel))
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(viewModel.balanceDescription(viewModel.balanceLevel))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.bottom, 20)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "contact.detail.circlePosition"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    HStack(spacing: 6) {
                        Image(systemName: "circle.grid.2x2.fill")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.primary)
                        Text(viewModel.circleLabel(contact.circle))
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(String(localized: "contact.detail.relationTags"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    HStack(spacing: 6) {
                        if !contact.relation.isEmpty {
                            ContactDetailSummaryTag(title: contact.relation)
                        }
                        if !contact.category.isEmpty {
                            ContactDetailSummaryTag(title: contact.category)
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ContactDetailAmountPair: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(value)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }
}

private struct ContactDetailSummaryTag: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DesignSystem.Typography.small)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DesignSystem.Colors.bgTag)
            .clipShape(Capsule())
    }
}
