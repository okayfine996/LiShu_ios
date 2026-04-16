import SwiftUI

struct RecordDetailHeroSection: View {
    let record: Record
    let directionLabel: String

    var body: some View {
        VStack(spacing: 12) {
            AvatarView(imageData: record.contact?.avatar, name: record.contact?.name ?? "", size: 80)

            Text(record.contact?.name ?? "")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            HStack(spacing: 8) {
                StatusBadge(badge: record.returnGiftBadge)
                RecordDetailDirectionTag(direction: record.direction, label: directionLabel)

                if !record.isMonetary {
                    RecordDetailTypeTag(recordType: record.recordType)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private var subtitle: String {
        [record.contact?.relation ?? "", record.contextDisplayName]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

struct RecordDetailAmountSection: View {
    let record: Record

    var body: some View {
        if cells.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 8) {
                ForEach(cells) { cell in
                    RecordDetailAmountCell(label: cell.label, value: cell.value)
                }
            }
        }
    }

    private var cells: [RecordDetailAmountCellModel] {
        if record.isMonetary {
            return [
                .init(
                    label: String(localized: "record.detail.giftAmount"),
                    value: RecordDetailFormatters.amount(record.monetaryAmount)
                ),
                .init(
                    label: String(localized: "record.detail.returnAmount"),
                    value: RecordDetailFormatters.amount(record.resolvedReturnedAmount)
                ),
            ]
        }

        if record.resolvedDisplayAmount > 0 {
            return [
                .init(
                    label: String(localized: "record.detail.giftAmount"),
                    value: RecordDetailFormatters.amount(record.resolvedDisplayAmount)
                ),
            ]
        }

        return []
    }
}

struct RecordDetailTypeSummarySection: View {
    let record: Record

    var body: some View {
        if record.isMonetary {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Text(record.recordType.iconEmoji)
                        .font(DesignSystem.Typography.caption)
                    Text(record.recordType.displayName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.semibold)
                }

                typeSpecificContent
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    @ViewBuilder
    private var typeSpecificContent: some View {
        switch record.resolvedTypeData {
        case let .gift(data):
            RecordDetailLabeledValueRow(
                title: String(localized: "record.detail.giftName"),
                value: data.giftName
            )

            if let estimatedValue = data.estimatedValue, estimatedValue > 0 {
                RecordDetailLabeledValueRow(
                    title: String(localized: "record.detail.estimatedValue"),
                    value: RecordDetailFormatters.amount(estimatedValue)
                )
            }
        case let .banquet(data):
            if !data.location.isEmpty {
                RecordDetailLabeledValueRow(
                    title: String(localized: "record.add.banquet.location"),
                    value: data.location
                )
            }

            if !data.attendeeList.isEmpty {
                RecordDetailLabeledValueRow(
                    title: String(localized: "record.add.banquet.attendees"),
                    value: data.attendeeList,
                    multiline: true
                )
            }

            if !data.extraCostNotes.isEmpty {
                RecordDetailLabeledValueRow(
                    title: String(localized: "record.add.banquet.extraCostNotes"),
                    value: data.extraCostNotes,
                    multiline: true
                )
            }
        default:
            if !record.resolvedDescription.isEmpty {
                Text(record.resolvedDescription)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineSpacing(4)
            }
        }
    }
}

struct RecordDetailInfoCard: View {
    let record: Record
    let paymentMethodName: String
    let formattedDate: String

    var body: some View {
        VStack(spacing: 0) {
            RecordDetailInfoRow(
                icon: "doc.text",
                label: String(localized: "record.add.recordType"),
                value: record.recordType.displayName
            )
            RecordDetailInfoDivider()
            RecordDetailInfoRow(
                icon: "slider.horizontal.3",
                label: String(localized: "record.detail.relationshipWeight"),
                value: record.relationshipWeight.displayName
            )
            RecordDetailInfoDivider()

            if record.isMonetary {
                RecordDetailInfoRow(
                    icon: "creditcard",
                    label: String(localized: "record.add.paymentMethod"),
                    value: paymentMethodName
                )
                RecordDetailInfoDivider()
            }

            RecordDetailInfoRow(
                icon: "calendar.badge.clock",
                label: String(localized: "record.add.date"),
                value: formattedDate
            )
        }
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }
}
