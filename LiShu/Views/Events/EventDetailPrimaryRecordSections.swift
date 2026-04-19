import SwiftData
import SwiftUI

struct EventDetailStandardView: View {
    let event: Event
    let records: [Record]
    let formattedDate: String
    let isUpcoming: Bool
    let daysUntilEvent: Int?
    @Binding var pendingDeleteRecord: Record?
    let onAddRecord: () -> Void
    var onSmartReturnGift: (() -> Void)?
    var smartReturnGiftBaseline: Double?

    private let rowInsets = EdgeInsets(
        top: 0,
        leading: DesignSystem.Spacing.pageHorizontal,
        bottom: DesignSystem.Spacing.block,
        trailing: DesignSystem.Spacing.pageHorizontal
    )

    var body: some View {
        List {
            if let coverData = event.coverImage {
                EventDetailCardListRow {
                    EventDetailCoverImageView(data: coverData)
                }
            }

            EventDetailCardListRow {
                EventDetailHeroCard(
                    event: event,
                    formattedDate: formattedDate,
                    isUpcoming: isUpcoming,
                    daysUntilEvent: daysUntilEvent
                )
            }

            if isUpcoming, let onSmartReturnGift {
                EventDetailCardListRow {
                    SmartReturnGiftBannerCard(
                        baselineAmount: smartReturnGiftBaseline,
                        onTap: onSmartReturnGift
                    )
                }
            }

            if !event.note.isEmpty {
                EventDetailCardListRow {
                    EventDetailNotesSection(note: event.note)
                }
            }

            EventDetailGiftRecordsSection(
                records: records,
                pendingDeleteRecord: $pendingDeleteRecord,
                onAddRecord: onAddRecord
            )
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.bgPage)
    }
}

private struct EventDetailCardListRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .listRowInsets(EdgeInsets(
                top: 0,
                leading: DesignSystem.Spacing.pageHorizontal,
                bottom: DesignSystem.Spacing.block,
                trailing: DesignSystem.Spacing.pageHorizontal
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

private struct EventDetailGiftRecordsSection: View {
    let records: [Record]
    @Binding var pendingDeleteRecord: Record?
    let onAddRecord: () -> Void

    private let rowInsets = EdgeInsets(
        top: 0,
        leading: DesignSystem.Spacing.pageHorizontal,
        bottom: DesignSystem.Spacing.block,
        trailing: DesignSystem.Spacing.pageHorizontal
    )

    var body: some View {
        Section {
            if records.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "event.detail.noPrimaryRecord"),
                    actionTitle: String(localized: "event.detail.addRecord"),
                    action: onAddRecord
                )
                .frame(height: 200)
                .listRowInsets(rowInsets)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(records) { record in
                    RecordRow(record: record)
                        .background(DesignSystem.Colors.bgSurface)
                        .overlay {
                            NavigationLink(destination: RecordDetailView(recordID: record.persistentModelID)) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                pendingDeleteRecord = record
                            } label: {
                                Label(String(localized: "common.delete"), systemImage: "trash")
                            }
                        }
                        .listRowInsets(rowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        } header: {
            HStack {
                Text(String(localized: "event.detail.giftRecords"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(String(format: String(localized: "event.list.recordCount"), records.count))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.bottom, DesignSystem.Spacing.block)
            .listRowInsets(EdgeInsets())
            .background(DesignSystem.Colors.bgPage)
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

// MARK: - Smart Return Gift Banner

struct SmartReturnGiftBannerCard: View {
    let baselineAmount: Double?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Colors.primary.opacity(0.85))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "event.smartGift.banner.title"))
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.bgSurface)

                    if let amount = baselineAmount {
                        let formatted = {
                            let f = NumberFormatter()
                            f.numberStyle = .decimal
                            f.maximumFractionDigits = 0
                            return "¥" + (f.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount))
                        }()
                        Text(String(format: String(localized: "event.smartGift.banner.subtitle"), formatted))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.bgSurface.opacity(0.8))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.bgSurface.opacity(0.7))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primary.opacity(0.75)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
        .buttonStyle(.plain)
    }
}
