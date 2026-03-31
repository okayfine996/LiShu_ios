import SwiftUI
import SwiftData

struct EventTypeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = EventTypeDetailViewModel()

    let eventType: EventType
    let year: Int

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                overviewCard
                monthlyChart
                recordList
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load(eventType: eventType, year: year, context: modelContext)
        }
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(String(localized: "eventDetail.totalCount"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(viewModel.totalCount)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(String(localized: "eventDetail.unit"))
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            Divider().foregroundStyle(DesignSystem.Colors.separator)

            HStack(spacing: 0) {
                statColumn(
                    label: String(localized: "eventDetail.expense"),
                    value: viewModel.formatAmount(viewModel.totalExpense),
                    color: DesignSystem.Colors.textPrimary
                )

                Rectangle()
                    .fill(DesignSystem.Colors.separator)
                    .frame(width: 1, height: 36)

                statColumn(
                    label: String(localized: "eventDetail.income"),
                    value: viewModel.formatAmount(viewModel.totalIncome),
                    color: DesignSystem.Colors.textPrimary
                )

                Rectangle()
                    .fill(DesignSystem.Colors.separator)
                    .frame(width: 1, height: 36)

                statColumn(
                    label: String(localized: "eventDetail.netValue"),
                    value: viewModel.formatNetValue(),
                    color: viewModel.netValue >= 0 ? DesignSystem.Colors.accentGold : DesignSystem.Colors.primary
                )
            }
        }
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    private func statColumn(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(value)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Monthly Distribution Chart

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "eventDetail.monthlyTrend"))
                .font(DesignSystem.Typography.small)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            let maxCount = max(viewModel.monthlyDistribution.max() ?? 1, 1)
            let chartHeight: CGFloat = 120

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<12, id: \.self) { idx in
                    let count = viewModel.monthlyDistribution[idx]
                    let isPeak = idx == viewModel.peakMonth && count > 0
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)

                        if count > 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isPeak ? DesignSystem.Colors.primary : DesignSystem.Colors.primary.opacity(0.2))
                                .frame(height: chartHeight * CGFloat(count) / CGFloat(maxCount))
                        }

                        Text("\(idx + 1)")
                            .font(.system(size: 10))
                            .fontWeight(isPeak ? .bold : .regular)
                            .foregroundStyle(isPeak ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: chartHeight + 20)
                }
            }
            .padding(.horizontal, 4)
            .padding(16)
            .background(DesignSystem.Colors.bgSurface.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                    .stroke(DesignSystem.Colors.bgSurface.opacity(0.6), lineWidth: 1)
            )
        }
    }

    // MARK: - Record List

    private var recordList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "eventDetail.records"))
                    .font(DesignSystem.Typography.small)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                Text(String(localized: "eventDetail.sortByDate"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            if viewModel.records.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "record.list.empty")
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.records) { record in
                        if let contact = record.contact, let event = record.event {
                            NavigationLink(value: AppRoute.contactExchange(contact.persistentModelID)) {
                                recordItem(record, contact: contact, event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func recordItem(_ record: Record, contact: Contact, event: Event) -> some View {
        HStack(spacing: 12) {
            AvatarView(imageData: contact.avatar, name: contact.name, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(contact.name)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(event.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(DesignSystem.Colors.primary.opacity(0.1), lineWidth: 1)
                        )
                }

                Text(formatDate(record.date))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(amountText(record))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        record.direction == .received
                            ? DesignSystem.Colors.accentGold
                            : DesignSystem.Colors.primary
                    )

                Text(record.direction == .received
                     ? String(localized: "eventDetail.received")
                     : String(localized: "eventDetail.given"))
                    .font(.system(size: 10))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(14)
        .contentShape(Rectangle())
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    // MARK: - Helpers

    private func amountText(_ record: Record) -> String {
        let prefix = record.direction == .received ? "+" : "-"
        return prefix + viewModel.formatAmount(record.resolvedDisplayAmount)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = String(localized: "exchange.dateFormat")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

private func makeEventTypeDetailPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext

    let c1 = Contact(name: "陈子健", relation: "朋友")
    let c2 = Contact(name: "林雨晴", relation: "同事")
    let c3 = Contact(name: "张伟达", relation: "同学")
    [c1, c2, c3].forEach { ctx.insert($0) }

    let e1 = Event(name: "陈子健婚礼", type: .wedding, date: .init())
    let e2 = Event(name: "林雨晴婚礼", type: .wedding, date: .init())
    let e3 = Event(name: "张伟达婚礼", type: .wedding, date: .init())
    [e1, e2, e3].forEach { ctx.insert($0) }

    let cal = Calendar.current
    let records: [Record] = [
        Record(contact: c1, event: e1, amount: 2000, direction: .received,
               date: cal.date(from: DateComponents(year: 2025, month: 10, day: 5))!),
        Record(contact: c2, event: e2, amount: 800, direction: .given,
               date: cal.date(from: DateComponents(year: 2025, month: 9, day: 21))!),
        Record(contact: c3, event: e3, amount: 1200, direction: .received,
               date: cal.date(from: DateComponents(year: 2025, month: 9, day: 15))!),
        Record(contact: c1, event: e1, amount: 600, direction: .received,
               date: cal.date(from: DateComponents(year: 2025, month: 3, day: 10))!),
        Record(contact: c2, event: e2, amount: 1500, direction: .given,
               date: cal.date(from: DateComponents(year: 2025, month: 5, day: 20))!),
    ]
    records.forEach { ctx.insert($0) }

    return container
}

#Preview {
    Group {
        if let container = makeEventTypeDetailPreviewContainer() {
            NavigationStack {
                EventTypeDetailView(eventType: .wedding, year: 2025)
            }
            .modelContainer(container)
        } else {
            Text("Preview unavailable")
        }
    }
}
