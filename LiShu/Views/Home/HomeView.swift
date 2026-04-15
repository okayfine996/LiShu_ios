import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Record.date, order: .reverse) private var records: [Record]
    @Query private var contacts: [Contact]
    @Query private var events: [Event]
    @State private var sheetRoute: SheetRoute?

    private var snapshot: HomeDashboardSnapshot {
        HomeDashboardSnapshot.build(records: records, events: events, contacts: contacts)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                summarySection(snapshot)
                ledgerSection(snapshot)
                upcomingSection(snapshot)
                recentRecordsSection(snapshot)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "home.title"))
        .navigationBarTitleDisplayMode(.automatic)
        .sheet(item: $sheetRoute) { route in
            sheetContent(for: route)
        }
    }

    // MARK: - Summary Section

    private func summarySection(_ snapshot: HomeDashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Text(String(localized: "home.yearSummaryTitle"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(lunarYearLabel)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    financialSummaryCard(snapshot)
                        .frame(width: summaryCardWidth, alignment: .top)

                    relationshipSummaryCard(snapshot)
                        .frame(width: summaryCardWidth, alignment: .top)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .frame(height: 320)
        }
    }

    private var summaryCardWidth: CGFloat {
        UIScreen.main.bounds.width - (DesignSystem.Spacing.pageHorizontal * 2) - 4
    }

    private func financialSummaryCard(_ snapshot: HomeDashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                summaryCardTitle(
                    icon: "wallet.pass.fill",
                    title: String(localized: "home.financialAxisTitle")
                )

                Spacer()

                NavigationLink(value: AppRoute.statistics) {
                    Image(systemName: "chart.bar.fill")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(width: 40, height: 40)
                        .background(DesignSystem.Colors.bgIconSubtle)
                        .clipShape(Circle())
                }
                .accessibilityIdentifier("home.openStatistics")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "home.monetaryNetTitle"))
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                HStack(alignment: .center, spacing: 10) {
                    Text(formattedMonetaryNet(snapshot))
                        .font(DesignSystem.Typography.display)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let formattedYearOverYearChange = formattedYearOverYearChange(snapshot) {
                        Text(formattedYearOverYearChange)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(DesignSystem.Colors.bgInput)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                    }
                }
            }

            Divider()
                .foregroundStyle(DesignSystem.Colors.separator)

            HStack(spacing: 12) {
                financialDetailMetric(
                    title: String(localized: "home.income"),
                    amount: formattedIncome(snapshot),
                    ratio: snapshot.incomeRatio
                )

                financialDetailMetric(
                    title: String(localized: "home.expense"),
                    amount: formattedExpense(snapshot),
                    ratio: snapshot.expenseRatio
                )
            }

            HStack {
                Text(String(localized: "home.totalExchangeAmountTitle"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Text(formattedTotalExchangeAmount(snapshot))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DesignSystem.Colors.bgPage)
            .clipShape(Capsule())
        }
        .summaryCardChrome()
    }

    private func relationshipSummaryCard(_ snapshot: HomeDashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            summaryCardTitle(
                icon: "person.3.fill",
                title: String(localized: "home.relationshipAxisTitle")
            )

            summaryHeroMetric(
                title: String(localized: "home.interactionsTitle"),
                value: "\(snapshot.recordCount)",
                unit: String(localized: "home.interactionsUnitSuffix"),
                valueColor: DesignSystem.Colors.textPrimary
            )

            Divider()
                .foregroundStyle(DesignSystem.Colors.separator)

            HStack(spacing: 12) {
                relationshipDetailMetric(
                    title: String(localized: "home.activeContactsTitle"),
                    value: "\(snapshot.contactCount)",
                    detail: coreCircleSummary(snapshot)
                )

                relationshipDetailMetric(
                    title: String(localized: "home.nonFinancialInteractionsTitle"),
                    value: "\(snapshot.nonFinancialInteractionCount)",
                    detail: nonFinancialSummary(snapshot)
                )
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.top, 2)

                Text(String(localized: "home.relationshipInsightPlaceholder"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DesignSystem.Colors.bgPage)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            // TODO: Replace with dynamic relationship insight when the final copy strategy is ready.
        }
        .summaryCardChrome()
    }

    private func summaryCardTitle(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.primary)
        }
    }

    private func financialDetailMetric(title: String, amount: String, ratio: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(amount)
                .font(DesignSystem.Typography.title1)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            progressBar(progress: ratio)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func relationshipDetailMetric(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(value)
                .font(DesignSystem.Typography.title1)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(detail)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func progressBar(progress: Double) -> some View {
        GeometryReader { proxy in
            let clampedProgress = min(max(progress, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DesignSystem.Colors.bgInput)

                Capsule()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: clampedProgress == 0 ? 0 : max(proxy.size.width * clampedProgress, 36))
            }
        }
        .frame(height: 8)
    }

    private func summaryHeroMetric(
        title: String,
        value: String,
        unit: String? = nil,
        valueColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(DesignSystem.Typography.display)
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if let unit {
                    Text(unit)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Upcoming Events Section

    private func ledgerSection(_ snapshot: HomeDashboardSnapshot) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(localized: "event.ledger.sectionTitle"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Button(String(localized: "common.new")) {
                    sheetRoute = .addEvent
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.primary)
            }

            if snapshot.hostLedgerEvents.isEmpty {
                EmptyStateView(
                    icon: "book.closed",
                    message: String(localized: "event.ledger.homeEmpty"),
                    actionTitle: String(localized: "event.ledger.createHostEvent"),
                    action: {
                        sheetRoute = .addEvent
                    }
                )
                .frame(height: 220)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(snapshot.hostLedgerEvents) { event in
                            HomeLedgerCard(
                                event: event,
                                onPrimaryAction: {
                                    sheetRoute = .addLedgerReceipt(eventID: event.persistentModelID)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    private func upcomingSection(_ snapshot: HomeDashboardSnapshot) -> some View {
        VStack(spacing: 12) {
            sectionHeader(
                title: String(localized: "home.upcoming"),
                route: .eventList
            )

            if snapshot.upcomingEvents.isEmpty {
                emptyUpcomingCard
            } else {
                CarouselView(
                    pageCount: snapshot.upcomingEvents.count,
                    autoScrollInterval: 3
                ) { index in
                    Group {
                        if let event = snapshot.upcomingEvents.element(at: index) {
                            VStack {
                                NavigationLink(value: AppRoute.eventDetail(event.persistentModelID)) {
                                    upcomingEventCard(event)
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        } else {
                            Color.clear
                        }
                    }
                }
                .frame(height: 196)
            }
        }
    }

    private var emptyUpcomingCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .frame(width: 40, height: 40)
                .background(DesignSystem.Colors.bgIconSubtle)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))

            Text(String(localized: "home.noUpcoming"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Spacer()
        }
        .padding(14)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private func upcomingEventCard(_ event: Event) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let data = event.coverImage {
                    DecodedImageView(data: data, maxPixelSize: ImagePipeline.Preset.homeHeroMaxPixelSize)
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: eventGradientColors(event.type),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        Image(systemName: event.type.iconName)
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .overlay {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.08),
                        Color.black.opacity(0.26),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(event.type.displayName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.bgSurface.opacity(0.9))
                    .clipShape(Capsule())

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(formatEventDate(event.date))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 196)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.horizontal, 2)
    }

    // MARK: - Recent Records Section

    private func recentRecordsSection(_ snapshot: HomeDashboardSnapshot) -> some View {
        VStack(spacing: 12) {
            sectionHeader(
                title: String(localized: "home.recentRecords")
            )

            if snapshot.recentRecords.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "record.list.empty"),
                    actionTitle: String(localized: "home.addRecord"),
                    action: {
                        sheetRoute = .addRecord(direction: nil, contactID: nil, eventID: nil)
                    }
                )
                .accessibilityIdentifier("home.addRecordButton")
                .frame(height: 200)
            } else {
                VStack(spacing: 10) {
                    ForEach(snapshot.recentRecords) { record in
                        NavigationLink(value: AppRoute.recordDetail(record.persistentModelID)) {
                            recentRecordCard(record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func recentRecordCard(_ record: Record) -> some View {
        HStack(spacing: 12) {
            AvatarView(imageData: record.contact?.avatar, name: record.contact?.name ?? "")

            VStack(alignment: .leading, spacing: 3) {
                Text(record.contact?.name ?? "")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(record.contextDisplayName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if record.isMonetary {
                    Text("¥" + String(format: "%.0f", record.monetaryAmount))
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primary)
                } else {
                    HStack(spacing: 4) {
                        Text(record.recordType.iconEmoji)
                            .font(DesignSystem.Typography.caption)
                        Text(record.resolvedDescription)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                    }
                }
                Text(relativeDateText(record.date))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, route: AppRoute? = nil) -> some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            if let route {
                NavigationLink(value: route) {
                    Text(String(localized: "common.viewAll"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
    }

    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "M月dd日"
        return formatter.string(from: date)
    }

    private var lunarYearLabel: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .chinese)
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "U年"
        return formatter.string(from: Date())
    }

    private func formattedIncome(_ snapshot: HomeDashboardSnapshot) -> String {
        "¥" + formatCompactNumber(snapshot.yearlyIncome)
    }

    private func formattedExpense(_ snapshot: HomeDashboardSnapshot) -> String {
        "¥" + formatCompactNumber(snapshot.yearlyExpense)
    }

    private func formattedTotalExchangeAmount(_ snapshot: HomeDashboardSnapshot) -> String {
        "¥" + formatAmountWithComma(snapshot.totalExchangeAmount)
    }

    private func formattedMonetaryNet(_ snapshot: HomeDashboardSnapshot) -> String {
        formatNetValue(snapshot.yearlyIncome - snapshot.yearlyExpense)
    }

    private func formattedYearOverYearChange(_ snapshot: HomeDashboardSnapshot) -> String? {
        guard let yearOverYearChangeRate = snapshot.yearOverYearChangeRate else { return nil }
        let sign = yearOverYearChangeRate >= 0 ? "+" : "-"
        return String(
            format: String(localized: "statistics.hero.yoy"),
            sign,
            abs(yearOverYearChangeRate) * 100
        )
    }

    private func coreCircleSummary(_ snapshot: HomeDashboardSnapshot) -> String {
        String(format: String(localized: "home.coreCircleShareFormat"), snapshot.coreCircleRatioPercent)
    }

    private func nonFinancialSummary(_ snapshot: HomeDashboardSnapshot) -> String {
        String(format: String(localized: "home.nonFinancialSummaryFormat"), snapshot.nonFinancialInteractionCount)
    }

    private func formatCompactNumber(_ value: Double) -> String {
        if value >= 10000 {
            return String(format: String(localized: "number.tenThousandsFormat"), value / 10000)
        }
        return String(format: "%.0f", value)
    }

    private func formatAmountWithComma(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
    }

    private func formatNetValue(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return prefix + "¥" + formatAmountWithComma(value)
    }

    private func relativeDateText(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let recordDay = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: recordDay, to: today).day ?? 0

        if days == 0 {
            return String(localized: "home.today")
        } else if days == 1 {
            return String(localized: "home.yesterday")
        } else if days < 7 {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_Hans")
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_Hans")
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }

    private func eventGradientColors(_ type: EventType) -> [Color] {
        switch type {
        case .wedding, .engagement:
            [DesignSystem.Colors.primary.opacity(0.3), DesignSystem.Colors.primary.opacity(0.1)]
        case .birthday, .longevity:
            [DesignSystem.Colors.accentGold.opacity(0.3), DesignSystem.Colors.accentGold.opacity(0.1)]
        case .education, .promotion:
            [DesignSystem.Colors.primary.opacity(0.2), DesignSystem.Colors.accentGold.opacity(0.15)]
        case .funeral, .visit:
            [DesignSystem.Colors.textSecondary.opacity(0.2), DesignSystem.Colors.textSecondary.opacity(0.1)]
        case .festival:
            [DesignSystem.Colors.primary.opacity(0.25), DesignSystem.Colors.accentGold.opacity(0.2)]
        case .property, .business:
            [DesignSystem.Colors.accentGold.opacity(0.25), DesignSystem.Colors.primary.opacity(0.15)]
        case .birth:
            [DesignSystem.Colors.primary.opacity(0.2), DesignSystem.Colors.primary.opacity(0.08)]
        case .other:
            [DesignSystem.Colors.textSecondary.opacity(0.15), DesignSystem.Colors.bgCard]
        }
    }

    private func eventTypeIcon(_ type: EventType) -> (name: String, color: Color) {
        (type.iconName, DesignSystem.Colors.primary)
    }

    @ViewBuilder
    private func sheetContent(for route: SheetRoute) -> some View {
        switch route {
        case let .addRecord(direction, contactID, eventID):
            NavigationStack {
                AddRecordView(direction: direction, contactID: contactID, eventID: eventID)
            }
        case let .addLedgerReceipt(eventID):
            NavigationStack {
                AddLedgerReceiptView(eventID: eventID)
            }
        case .addContact:
            NavigationStack {
                AddContactView()
            }
        case .addEvent:
            NavigationStack {
                AddEventView(defaultHostMode: .host)
            }
        case let .editContact(contactID):
            NavigationStack {
                AddContactView(contactID: contactID)
            }
        case let .editEvent(eventID):
            NavigationStack {
                AddEventView(eventID: eventID)
            }
        case let .editRecord(recordID):
            NavigationStack {
                AddRecordView(recordID: recordID)
            }
        case let .returnGift(recordID):
            NavigationStack {
                ReturnGiftSheet(recordID: recordID)
            }
        case let .ocrImport(eventID):
            OCRImportView(eventID: eventID)
        case .proMembership:
            NavigationStack {
                ProMembershipView()
            }
        }
    }
}

private extension Array {
    func element(at index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

@MainActor
private func makeHomePreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self, RecordPhoto.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    DemoDataSeeding.insertSampleData(context: container.mainContext, attachDemoMedia: false)
    return container
}

#Preview {
    Group {
        if let container = makeHomePreviewContainer() {
            NavigationStack {
                HomeView()
            }
            .modelContainer(container)
            .environment(SubscriptionManager.shared)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}

private extension View {
    func summaryCardChrome() -> some View {
        padding(.horizontal, DesignSystem.Spacing.cardPadding)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .stroke(DesignSystem.Colors.primary.opacity(0.08), lineWidth: 1)
            )
    }
}
