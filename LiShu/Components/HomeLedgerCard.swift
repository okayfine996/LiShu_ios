import SwiftData
import SwiftUI

struct HomeLedgerCard: View {
    @State private var isShowingEventDetail = false

    let event: Event
    let onPrimaryAction: () -> Void

    private var receivedRecords: [Record] {
        (event.records ?? [])
            .filter { $0.direction == .received }
            .sorted { $0.date > $1.date }
    }

    private var totalReceived: Double {
        receivedRecords.reduce(0) { $0 + $1.resolvedDisplayAmount }
    }

    private var receivedCount: Int {
        receivedRecords.count
    }

    private var todayReceivedCount: Int {
        let calendar = Calendar.current
        return receivedRecords.filter { calendar.isDateInToday($0.date) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            headerSection
            metricsSection
            actionSection
        }
        .padding(DesignSystem.Spacing.heroCardPadding)
        .frame(width: DesignSystem.Layout.homeLedgerCardWidth, alignment: .leading)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.border.opacity(0.6), lineWidth: 1)
        )
        .shadow(
            color: DesignSystem.Colors.textPrimary.opacity(0.08),
            radius: DesignSystem.Spacing.dense,
            x: 0,
            y: DesignSystem.Spacing.stackTight
        )
        .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .onTapGesture {
            isShowingEventDetail = true
        }
        .navigationDestination(isPresented: $isShowingEventDetail) {
            EventDetailView(eventID: event.persistentModelID)
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.block) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                Text(event.type.displayName + " · " + event.name)
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)

                HStack(spacing: DesignSystem.Spacing.dense) {
                    Image(systemName: "calendar")
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text(formattedDate(event.date) + " · " + locationText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }

            Spacer(minLength: DesignSystem.Spacing.block)

            Button {
                isShowingEventDetail = true
            } label: {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                    .fill(DesignSystem.Colors.bgIconSubtle)
                    .frame(
                        width: DesignSystem.Layout.homeLedgerIconTileSize,
                        height: DesignSystem.Layout.homeLedgerIconTileSize
                    )
                    .overlay {
                        Image(systemName: "book.closed")
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    private var metricsSection: some View {
        HStack(spacing: DesignSystem.Spacing.block) {
            metricColumn(
                title: String(localized: "event.ledger.totalAmount"),
                value: "¥ " + formatAmount(totalReceived),
                valueColor: DesignSystem.Colors.primary
            )

            metricDivider

            metricColumn(
                title: String(localized: "event.ledger.totalCount"),
                value: String(format: String(localized: "event.ledger.countValue"), receivedCount),
                valueColor: DesignSystem.Colors.textPrimary
            )

            metricDivider

            metricColumn(
                title: String(localized: "event.ledger.todaySummary"),
                value: String(format: String(localized: "event.ledger.countValue"), todayReceivedCount),
                valueColor: DesignSystem.Colors.textPrimary
            )
        }
    }

    private var actionSection: some View {
        Button(action: onPrimaryAction) {
            Label(String(localized: "event.ledger.primaryAction"), systemImage: "plus.circle.fill")
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(DesignSystem.Colors.separator)
            .frame(maxWidth: 1)
    }

    private func metricColumn(title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
            Text(title)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .lineLimit(1)

            Text(value)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var locationText: String {
        event.location.isEmpty ? String(localized: "record.context.daily") : event.location
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? String(Int(amount))
    }
}

private func makeHomeLedgerCardPreviewContainer() -> (ModelContainer, Event)? {
    guard let container = try? ModelContainer(
        for: Contact.self,
        Record.self,
        Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }

    let context = container.mainContext
    let event = Event(
        name: "我的婚礼",
        type: .wedding,
        hostMode: .host,
        date: .now,
        location: "锦绣悦府"
    )
    let contacts = [
        Contact(name: "张三"),
        Contact(name: "李四"),
        Contact(name: "王芳"),
    ]
    let records = [
        Record.makeMonetaryRecord(contact: contacts[0], event: event, amount: 32000, direction: .received, paymentMethod: .wechat),
        Record.makeMonetaryRecord(contact: contacts[1], event: event, amount: 28000, direction: .received, paymentMethod: .cash),
        Record.makeMonetaryRecord(contact: contacts[2], event: event, amount: 28200, direction: .received, paymentMethod: .alipay),
    ]

    context.insert(event)
    contacts.forEach { context.insert($0) }
    records.forEach { context.insert($0) }
    try? context.save()

    return (container, event)
}

#Preview {
    if let (container, event) = makeHomeLedgerCardPreviewContainer() {
        NavigationStack {
            HomeLedgerCard(
                event: event,
                onPrimaryAction: {}
            )
            .padding()
            .background(DesignSystem.Colors.bgPage)
        }
        .modelContainer(container)
    }
}
