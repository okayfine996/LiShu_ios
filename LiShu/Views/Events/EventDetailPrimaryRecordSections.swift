import SwiftData
import SwiftUI

struct EventDetailStandardView: View {
    let event: Event
    let primaryRecord: Record?
    let formattedDate: String
    let isUpcoming: Bool
    let daysUntilEvent: Int?
    let onAddRecord: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if let coverData = event.coverImage {
                    EventDetailCoverImageView(data: coverData)
                }

                EventDetailHeroCard(
                    event: event,
                    formattedDate: formattedDate,
                    isUpcoming: isUpcoming,
                    daysUntilEvent: daysUntilEvent
                )

                EventDetailPrimaryRecordSection(
                    eventID: event.persistentModelID,
                    primaryRecord: primaryRecord,
                    onAddRecord: onAddRecord
                )

                if !event.note.isEmpty {
                    EventDetailNotesSection(note: event.note)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

private struct EventDetailPrimaryRecordSection: View {
    let eventID: PersistentIdentifier
    let primaryRecord: Record?
    let onAddRecord: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "event.detail.primaryRecord"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if let primaryRecord {
                NavigationLink {
                    RecordDetailView(recordID: primaryRecord.persistentModelID)
                } label: {
                    EventDetailPrimaryRecordCard(record: primaryRecord)
                }
                .buttonStyle(.plain)
            } else {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "event.detail.noPrimaryRecord"),
                    actionTitle: String(localized: "event.detail.addRecord"),
                    action: onAddRecord
                )
                .frame(height: 180)
            }
        }
    }
}

private struct EventDetailPrimaryRecordCard: View {
    let record: Record

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: record.recordType.iconName)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Colors.bgIconSubtle)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(titleText)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text(subtitleText)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.small)
                    .fontWeight(.medium)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            VStack(spacing: 10) {
                typeDetails
                EventDetailPrimaryRecordMetaRow(
                    label: String(localized: "record.add.date"),
                    value: EventDetailRecordFormatters.dateTime(record.date)
                )
                EventDetailPrimaryRecordMetaRow(
                    label: String(localized: "record.detail.relationshipWeight"),
                    value: record.relationshipWeight.displayName
                )

                if !record.note.isEmpty {
                    EventDetailPrimaryRecordMetaRow(
                        label: String(localized: "event.detail.notes"),
                        value: record.note
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    @ViewBuilder
    private var typeDetails: some View {
        switch record.resolvedTypeData {
        case let .monetary(data):
            EventDetailPrimaryRecordMetaRow(
                label: String(localized: "record.detail.giftAmount"),
                value: EventDetailRecordFormatters.currency(data.amount)
            )
            EventDetailPrimaryRecordMetaRow(
                label: String(localized: "record.add.paymentMethod"),
                value: paymentMethodText
            )
        case let .gift(data):
            EventDetailPrimaryRecordMetaRow(
                label: String(localized: "record.detail.giftName"),
                value: data.giftName
            )
            if let estimatedValue = data.estimatedValue, estimatedValue > 0 {
                EventDetailPrimaryRecordMetaRow(
                    label: String(localized: "record.detail.estimatedValue"),
                    value: EventDetailRecordFormatters.currency(estimatedValue)
                )
            }
        case let .favor(data):
            if !data.description.isEmpty {
                EventDetailPrimaryRecordMetaRow(
                    label: record.recordType.displayName,
                    value: data.description
                )
            }
        case let .banquet(data):
            if !data.location.isEmpty {
                EventDetailPrimaryRecordMetaRow(
                    label: String(localized: "record.add.banquet.location"),
                    value: data.location
                )
            }
            if !data.attendeeList.isEmpty {
                EventDetailPrimaryRecordMetaRow(
                    label: String(localized: "record.add.banquet.attendees"),
                    value: data.attendeeList
                )
            }
            if !data.extraCostNotes.isEmpty {
                EventDetailPrimaryRecordMetaRow(
                    label: String(localized: "record.add.banquet.extraCostNotes"),
                    value: data.extraCostNotes
                )
            }
        }
    }

    private var titleText: String {
        switch record.resolvedTypeData {
        case .monetary:
            String(localized: "event.detail.monetaryRecordTitle")
        case let .gift(data):
            data.giftName.isEmpty ? record.recordType.displayName : data.giftName
        case let .favor(data):
            data.description.isEmpty ? record.recordType.displayName : data.description
        case let .banquet(data):
            if !data.location.isEmpty {
                data.location
            } else if !data.attendeeList.isEmpty {
                data.attendeeList
            } else {
                record.recordType.displayName
            }
        }
    }

    private var subtitleText: String {
        [
            record.direction == .given
                ? String(localized: "record.detail.directionSent")
                : String(localized: "record.detail.directionReceived"),
            record.contact?.name,
        ]
        .compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }
        .joined(separator: " · ")
    }

    private var paymentMethodText: String {
        switch record.resolvedPaymentMethod {
        case .cash:
            String(localized: "payment.cash")
        case .wechat:
            String(localized: "payment.wechat")
        case .alipay:
            String(localized: "payment.alipay")
        }
    }
}

private struct EventDetailPrimaryRecordMetaRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer(minLength: 12)

            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private enum EventDetailRecordFormatters {
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter
    }()

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func dateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    static func currency(_ amount: Double) -> String {
        let formatted = currencyFormatter.string(from: NSNumber(value: amount))
            ?? String(format: "%.0f", amount)
        return "¥" + formatted
    }
}
