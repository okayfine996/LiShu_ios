import SwiftData
import SwiftUI

struct ContactExchangeContentView: View {
    let contact: Contact
    let records: [Record]
    let totalGivenText: String
    let totalReceivedText: String
    let netLabel: String
    let netAmountText: String
    let givenRatio: Double
    let lastContactText: String?
    let formatDate: (Date) -> String
    let amountText: (Record) -> String

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ContactExchangeProfileSection(
                    contact: contact,
                    lastContactText: lastContactText
                )
                ContactExchangeSummarySection(
                    totalGivenText: totalGivenText,
                    totalReceivedText: totalReceivedText
                )
                ContactExchangeNetValueSection(
                    netLabel: netLabel,
                    netAmountText: netAmountText,
                    givenRatio: givenRatio
                )
                ContactExchangeTimelineSection(
                    records: records,
                    formatDate: formatDate,
                    amountText: amountText
                )
            }
            .padding(.bottom, 32)
        }
    }
}

private struct ContactExchangeProfileSection: View {
    let contact: Contact
    let lastContactText: String?

    var body: some View {
        VStack(spacing: 12) {
            AvatarView(imageData: contact.avatar, name: contact.name, size: 96)

            Text(contact.name)
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if !contact.relation.isEmpty || (!contact.category.isEmpty && contact.category != contact.relation) {
                HStack(spacing: 8) {
                    if !contact.relation.isEmpty {
                        ContactExchangeTag(text: contact.relation)
                    }

                    if !contact.category.isEmpty, contact.category != contact.relation {
                        ContactExchangeTag(text: contact.category)
                    }
                }
            }

            if let lastContactText {
                Text(String(localized: "exchange.lastContact") + lastContactText)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 24)
    }
}

private struct ContactExchangeTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DesignSystem.Typography.small)
            .fontWeight(.semibold)
            .foregroundStyle(DesignSystem.Colors.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(DesignSystem.Colors.primary.opacity(0.1))
            .clipShape(Capsule())
    }
}

private struct ContactExchangeSummarySection: View {
    let totalGivenText: String
    let totalReceivedText: String

    var body: some View {
        HStack(spacing: 12) {
            ContactExchangeCard(
                icon: "arrow.up.right",
                label: String(localized: "exchange.given"),
                amount: totalGivenText
            )
            ContactExchangeCard(
                icon: "arrow.down.left",
                label: String(localized: "exchange.received"),
                amount: totalReceivedText
            )
        }
        .padding(.horizontal, 16)
    }
}

private struct ContactExchangeCard: View {
    let icon: String
    let label: String
    let amount: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.small)
                Text(label)
                    .font(DesignSystem.Typography.small)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(amount)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}

private struct ContactExchangeNetValueSection: View {
    let netLabel: String
    let netAmountText: String
    let givenRatio: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom) {
                Text(String(localized: "exchange.netValue") + " (" + netLabel + ")")
                    .font(DesignSystem.Typography.small)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(netAmountText)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: geometry.size.width * givenRatio)

                    Rectangle()
                        .fill(DesignSystem.Colors.primary.opacity(0.3))
                }
                .frame(height: 10)
                .clipShape(Capsule())
            }
            .frame(height: 10)

            HStack {
                Text(String(format: String(localized: "exchange.ratio.given"), Int(givenRatio * 100)))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                Spacer()

                Text(String(format: String(localized: "exchange.ratio.received"), Int((1 - givenRatio) * 100)))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }
}

private struct ContactExchangeTimelineSection: View {
    let records: [Record]
    let formatDate: (Date) -> String
    let amountText: (Record) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(String(localized: "exchange.timeline"))
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            if records.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    message: String(localized: "exchange.timeline.empty")
                )
                .frame(height: 200)
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(records.enumerated()), id: \.element.persistentModelID) { index, record in
                        ContactExchangeTimelineRow(
                            record: record,
                            isLast: index == records.count - 1,
                            dateText: formatDate(record.date),
                            amountText: amountText(record)
                        )
                    }
                }
                .padding(.leading, 16)
            }
        }
    }
}

private struct ContactExchangeTimelineRow: View {
    let record: Record
    let isLast: Bool
    let dateText: String
    let amountText: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isLast ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.primary)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)

                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary.opacity(0.4),
                                    DesignSystem.Colors.primary.opacity(0.1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                }
            }
            .frame(width: 10)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(dateText)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Spacer()

                    Text(amountText)
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            record.direction == .received
                                ? DesignSystem.Colors.accentGold
                                : DesignSystem.Colors.primary
                        )
                }

                NavigationLink(value: AppRoute.recordDetail(record.persistentModelID)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.contextDisplayName)
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        if !record.note.isEmpty {
                            Text(String(localized: "exchange.timeline.note") + record.note)
                                .font(DesignSystem.Typography.small)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .contentShape(Rectangle())
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 20)
            .padding(.trailing, 16)
            .padding(.bottom, isLast ? 0 : 24)
        }
    }
}
