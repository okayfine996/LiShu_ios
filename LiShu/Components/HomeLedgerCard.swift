import SwiftData
import SwiftUI

struct HomeLedgerCard: View {
    @State private var isShowingEventDetail = false

    let event: Event
    let onPrimaryAction: () -> Void
    let onGiftReceivingMode: () -> Void

    /// 首页礼簿卡只统计主场事件下真正收到的记录，避免把普通随礼混进来。
    private var receivedRecords: [Record] {
        (event.records ?? [])
            .filter { $0.direction == .received && $0.recordType == .monetary }
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
            spotlightSection
            quickStatsSection
            actionSection
        }
        .padding(DesignSystem.Spacing.heroCardPadding)
        .frame(width: DesignSystem.Layout.homeLedgerCardWidth, alignment: .leading)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(
            color: DesignSystem.Colors.primary.opacity(0.08),
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
                Text(event.type.displayName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.accentGold)

                Text(event.name)
                    .font(DesignSystem.Typography.title1)
                    .foregroundStyle(DesignSystem.Colors.primary)
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

            // 右上角书本图标和整张卡片都进入详情，符合"看礼簿"的操作预期。
            Button {
                isShowingEventDetail = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "book.closed")
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.primary)

                    Text(String(localized: "common.viewAll"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .frame(
                    width: DesignSystem.Layout.homeLedgerIconTileSize,
                    height: DesignSystem.Layout.homeLedgerIconTileSize
                )
                .background(DesignSystem.Colors.bgIconSubtle)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
            }
            .buttonStyle(.plain)
        }
    }

    private var spotlightSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.inlineTight) {
            Text(String(localized: "event.ledger.totalAmount"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text("¥" + formatAmount(totalReceived))
                .font(DesignSystem.Typography.display)
                .foregroundStyle(DesignSystem.Colors.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Capsule()
                .fill(DesignSystem.Colors.primary.opacity(0.14))
                .frame(width: 72, height: 6)
        }
    }

    private var quickStatsSection: some View {
        HStack(spacing: DesignSystem.Spacing.block) {
            compactMetric(
                title: String(localized: "event.ledger.totalCount"),
                value: String(format: String(localized: "event.ledger.countValue"), receivedCount)
            )

            compactMetric(
                title: String(localized: "event.ledger.todaySummary"),
                value: String(format: String(localized: "event.ledger.countValue"), todayReceivedCount)
            )
        }
    }

    private var actionSection: some View {
        HStack(spacing: DesignSystem.Spacing.inlineTight) {
            Button(action: onPrimaryAction) {
                HStack(spacing: DesignSystem.Spacing.dense) {
                    Image(systemName: "plus.circle.fill")
                    Text(String(localized: "event.ledger.primaryAction"))
                        .fontWeight(.semibold)
                }
                .font(DesignSystem.Typography.caption)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .guideAnchor(id: "home.ledger.receiptButton")

            Button(action: onGiftReceivingMode) {
                HStack(spacing: DesignSystem.Spacing.dense) {
                    Image(systemName: "hands.and.sparkles")
                    Text(String(localized: "giftReceiving.nav.title"))
                        .fontWeight(.semibold)
                }
                .font(DesignSystem.Typography.caption)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func compactMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
            Text(title)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .lineLimit(1)

            Text(value)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, DesignSystem.Spacing.cardPaddingSmall)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.bgPage)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                .stroke(DesignSystem.Colors.primary.opacity(0.04), lineWidth: 1)
        )
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
                onPrimaryAction: {},
                onGiftReceivingMode: {}
            )
            .frame(height: 320)
            .padding()
            .background(DesignSystem.Colors.bgPage)
        }
        .modelContainer(container)
    }
}
