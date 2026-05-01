import SwiftData
import SwiftUI

struct EventDetailLedgerView: View {
    let event: Event
    let viewModel: EventDetailViewModel
    @Binding var pendingDeleteRecord: Record?
    let onAddLedgerReceipt: () -> Void
    let onShowLegacyAnomalies: () -> Void
    let onOpenGiftReceivingMode: () -> Void

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
                    formattedDate: viewModel.formattedDate,
                    isUpcoming: viewModel.isUpcoming,
                    daysUntilEvent: viewModel.daysUntilEvent
                )
            }

            if viewModel.hasLegacyLedgerAnomalies {
                EventDetailCardListRow {
                    Button(action: onShowLegacyAnomalies) {
                        EventDetailLegacyWarningBanner(
                            anomalyCount: viewModel.legacyLedgerAnomalyCount,
                            previewText: viewModel.legacyLedgerAnomalyPreviewText
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            EventDetailCardListRow {
                EventDetailLedgerSummaryCards(viewModel: viewModel)
            }

            EventDetailCardListRow {
                GiftReceivingModeTriggerCard(action: onOpenGiftReceivingMode)
            }

            EventDetailLedgerRecordsSection(
                records: viewModel.receivedRecords,
                pendingDeleteRecord: $pendingDeleteRecord,
                onAddLedgerReceipt: onAddLedgerReceipt
            )

            if !event.note.isEmpty {
                EventDetailCardListRow {
                    EventDetailNotesSection(note: event.note)
                }
            }
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

private struct EventDetailLegacyWarningBanner: View {
    let anomalyCount: Int
    let previewText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.accentGold)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 12) {
                Text(
                    String(
                        format: String(localized: "event.ledger.legacyWarning %lld"),
                        Int64(anomalyCount)
                    )
                )
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

                if !previewText.isEmpty {
                    Text(previewText)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Spacer(minLength: 0)
                    Text(String(localized: "common.viewAll"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(DesignSystem.Colors.accentGold.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}

private struct EventDetailLedgerSummaryCards: View {
    let viewModel: EventDetailViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                EventDetailLedgerSummaryCard(
                    icon: "banknote",
                    title: String(localized: "event.ledger.totalAmount"),
                    value: CurrencyFormatter.wholeAmount(viewModel.totalReceived),
                    tint: DesignSystem.Colors.primary
                )
                EventDetailLedgerSummaryCard(
                    icon: "person.2.fill",
                    title: String(localized: "event.ledger.totalCount"),
                    value: String(
                        format: String(localized: "event.ledger.countValue"),
                        viewModel.receivedRecordCount
                    ),
                    tint: DesignSystem.Colors.accentGold
                )
            }

            HStack(spacing: 12) {
                EventDetailLedgerSummaryCard(
                    icon: "arrow.up.forward.circle",
                    title: String(localized: "event.ledger.maxAmount"),
                    value: CurrencyFormatter.wholeAmount(viewModel.largestReceivedAmount),
                    tint: DesignSystem.Colors.primary
                )
                EventDetailLedgerSummaryCard(
                    icon: "sun.max.fill",
                    title: String(localized: "event.ledger.todaySummary"),
                    value: String(
                        format: String(localized: "event.ledger.todayValue"),
                        viewModel.todayReceivedCount,
                        viewModel.todayReceivedAmount
                    ),
                    tint: DesignSystem.Colors.accentGold
                )
            }
        }
    }
}

private struct EventDetailLedgerSummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12))
                .clipShape(Circle())

            Text(title)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.semibold)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}

private struct EventDetailLedgerRecordsSection: View {
    let records: [Record]
    @Binding var pendingDeleteRecord: Record?
    let onAddLedgerReceipt: () -> Void

    var body: some View {
        Section {
            if records.isEmpty {
                EmptyStateView(
                    icon: "book.closed",
                    message: String(localized: "event.ledger.empty"),
                    actionTitle: String(localized: "event.ledger.primaryAction"),
                    action: onAddLedgerReceipt
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
                Text(String(localized: "event.ledger.allRecords"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(String(format: String(localized: "event.list.recordCount"), records.count))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.bottom, DesignSystem.Spacing.block)
        }
        .textCase(nil)
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(
            top: 0,
            leading: DesignSystem.Spacing.pageHorizontal,
            bottom: DesignSystem.Spacing.block,
            trailing: DesignSystem.Spacing.pageHorizontal
        )
    }
}

private struct GiftReceivingModeTriggerCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.inlineTight) {
                Image(systemName: "hands.and.sparkles")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: 36, height: 36)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "giftReceiving.trigger.button"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(String(localized: "giftReceiving.trigger.subtitle"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.block)
            .background(DesignSystem.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        }
        .buttonStyle(.plain)
    }
}

private enum CurrencyFormatter {
    static func wholeAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: amount))
            ?? String(format: "%.0f", amount)
        return "¥" + formatted
    }
}
