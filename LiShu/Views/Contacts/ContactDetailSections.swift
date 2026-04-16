import SwiftData
import SwiftUI

struct ContactDetailProfileSection: View {
    let contact: Contact

    var body: some View {
        VStack(spacing: 8) {
            AvatarView(imageData: contact.avatar, name: contact.name, size: 80)
                .overlay {
                    Circle()
                        .stroke(DesignSystem.Colors.bgSurface, lineWidth: 1)
                }

            Text(contact.name)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if !contact.category.isEmpty || !contact.relation.isEmpty {
                HStack(spacing: 6) {
                    if !contact.relation.isEmpty {
                        ContactDetailTag(
                            title: contact.relation,
                            foreground: DesignSystem.Colors.primary,
                            background: DesignSystem.Colors.primary.opacity(0.12)
                        )
                    }
                    if !contact.category.isEmpty {
                        ContactDetailTag(
                            title: contact.category,
                            foreground: DesignSystem.Colors.textSecondary,
                            background: DesignSystem.Colors.bgTag
                        )
                    }
                }
            }

            if !contact.location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(DesignSystem.Typography.small)
                    Text(contact.location)
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }
}

struct ContactDetailPersonalInfoSection: View {
    let contact: Contact
    let viewModel: ContactDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "contact.detail.personalInfo"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                if let birthday = contact.birthday {
                    ContactDetailInfoRow(
                        icon: "birthday.cake.fill",
                        label: String(localized: "contact.add.birthday"),
                        value: viewModel.formatDate(birthday)
                    )
                    ContactDetailInfoDivider()
                }

                ContactDetailInfoRow(
                    icon: "circle.grid.2x2.fill",
                    label: String(localized: "contact.detail.circle"),
                    value: viewModel.circleText(contact.circle)
                )

                if !contact.phone.isEmpty {
                    ContactDetailInfoDivider()
                    ContactDetailInfoRow(
                        icon: "phone.fill",
                        label: String(localized: "contact.add.phone"),
                        value: contact.phone
                    )
                }

                if !contact.note.isEmpty {
                    ContactDetailInfoDivider()
                    ContactDetailInfoRow(
                        icon: "note.text",
                        label: String(localized: "contact.add.notes"),
                        value: contact.note
                    )
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
            .padding(.horizontal, 16)
        }
    }
}

struct ContactDetailTimelineSection: View {
    let records: [Record]
    let viewModel: ContactDetailViewModel
    let onAddRecord: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(String(localized: "contact.detail.timeline"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Button(action: onAddRecord) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .font(DesignSystem.Typography.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            if records.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "contact.detail.noRecords")
                )
                .frame(height: 160)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(records.enumerated()), id: \.element.persistentModelID) { index, record in
                        ContactDetailTimelineEntry(
                            record: record,
                            dateText: viewModel.timelineDateText(record.date),
                            amountText: timelineAmountText(record),
                            amountColor: timelineAmountColor(record),
                            isLast: index == records.count - 1
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func timelineAmountText(_ record: Record) -> String? {
        switch record.recordType {
        case .monetary:
            let prefix = record.direction == .received ? "+" : "-"
            return prefix + viewModel.formatAmount(record.resolvedDisplayAmount)
        case .gift:
            if let estimated = record.resolvedEstimatedValue, estimated > 0 {
                return String(localized: "contact.detail.estimated") + " " + viewModel.formatAmount(estimated)
            }
            return nil
        case .favor:
            return nil
        case .banquet:
            return nil
        }
    }

    private func timelineAmountColor(_ record: Record) -> Color {
        switch record.recordType {
        case .monetary:
            record.direction == .received
                ? DesignSystem.Colors.accentGold
                : DesignSystem.Colors.primary
        case .gift, .banquet:
            DesignSystem.Colors.textSecondary
        case .favor:
            DesignSystem.Colors.primary
        }
    }
}

private struct ContactDetailTag: View {
    let title: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(title)
            .font(DesignSystem.Typography.small)
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }
}

private struct ContactDetailInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 24, height: 24)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct ContactDetailInfoDivider: View {
    var body: some View {
        Divider()
            .background(DesignSystem.Colors.separator)
            .padding(.leading, 52)
    }
}

private struct ContactDetailTimelineEntry: View {
    let record: Record
    let dateText: String
    let amountText: String?
    let amountColor: Color
    let isLast: Bool

    var body: some View {
        NavigationLink(value: AppRoute.recordDetail(record.persistentModelID)) {
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) {
                    Circle()
                        .stroke(DesignSystem.Colors.border, lineWidth: 1.5)
                        .frame(width: 10, height: 10)
                        .background(Circle().fill(DesignSystem.Colors.bgPage))
                        .padding(.top, 6)

                    if !isLast {
                        Rectangle()
                            .fill(DesignSystem.Colors.separator)
                            .frame(width: 1)
                    }
                }
                .frame(width: 10)

                Spacer().frame(width: 12)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        Text(dateText)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)

                        Spacer()

                        ContactDetailTimelineMeta(
                            record: record,
                            amountText: amountText,
                            amountColor: amountColor
                        )
                        .frame(width: DesignSystem.Layout.timelineMetaWidth, alignment: .trailing)
                    }

                    HStack(spacing: 8) {
                        ContactDetailTimelineTypeTag(type: record.recordType)

                        Text(record.contextDisplayName)
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                    }

                    if !record.note.isEmpty {
                        Text(record.note)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(DesignSystem.Spacing.cardPaddingSmall)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
                .padding(.bottom, isLast ? 0 : 16)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ContactDetailTimelineMeta: View {
    let record: Record
    let amountText: String?
    let amountColor: Color

    var body: some View {
        switch record.recordType {
        case .monetary:
            if let amountText {
                Text(amountText)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(amountColor)
            }
        case .gift:
            if let amountText {
                Text(amountText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
        case .favor:
            Image(systemName: "heart.fill")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
        case .banquet:
            Image(systemName: "fork.knife")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }
}

private struct ContactDetailTimelineTypeTag: View {
    let type: RecordType

    var body: some View {
        Text(type.displayName)
            .font(DesignSystem.Typography.small)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))
    }

    private var color: Color {
        switch type {
        case .monetary: DesignSystem.Colors.primary
        case .gift: DesignSystem.Colors.accentGold
        case .favor: DesignSystem.Colors.textSecondary
        case .banquet: DesignSystem.Colors.textTertiary
        }
    }
}
