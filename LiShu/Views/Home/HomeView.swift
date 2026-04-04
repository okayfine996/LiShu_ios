import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var sheetRoute: SheetRoute?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                summarySection
                upcomingSection
                recentRecordsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "home.title"))
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            viewModel.load(context: modelContext)
        }
        .sheet(item: $sheetRoute) { route in
            sheetContent(for: route)
        }
        .onChange(of: sheetRoute) { _, newValue in
            if newValue == nil {
                viewModel.load(context: modelContext)
            }
        }
        #if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        DebugDataGenerator.generateSampleData(context: modelContext)
                        viewModel.load(context: modelContext)
                    } label: {
                        Label(String(localized: "debug.generateSampleData"), systemImage: "plus.circle")
                    }

                    Button(role: .destructive) {
                        DebugDataGenerator.clearAllData(context: modelContext)
                        viewModel.load(context: modelContext)
                    } label: {
                        Label(String(localized: "debug.clearAllData"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ladybug.fill")
                }
            }
        }
        #endif
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: title + add record button
            Text(String(localized: "home.yearSummaryTitle"))
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // Inner card: total interactions + type breakdown + monetary net
            summaryCardContent
        }
    }

    private var summaryCardContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Total interactions + chart button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "home.totalInteractions"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(viewModel.recordCount)")
                            .font(DesignSystem.Typography.display)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text(String(localized: "home.interactionUnit"))
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

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

            // Type breakdown capsules
            if !viewModel.typeBreakdown.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.typeBreakdown, id: \.type) { item in
                        typeCountCapsule(type: item.type, count: item.count)
                    }
                }
            }

            // Monetary net summary
            if viewModel.monetaryCount > 0 {
                Divider()
                    .foregroundStyle(DesignSystem.Colors.separator)

                Text(viewModel.monetaryNetSummary)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
        .padding(.vertical, DesignSystem.Spacing.heroCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private func typeCountCapsule(type: RecordType, count: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: type.iconName)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.primary)
            Text(String(format: String(localized: "home.typeCountFormat"), count))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DesignSystem.Colors.bgTag)
        .clipShape(Capsule())
    }

    // MARK: - Upcoming Events Section

    private var upcomingSection: some View {
        VStack(spacing: 12) {
            sectionHeader(
                title: String(localized: "home.upcoming"),
                route: .eventList
            )

            if viewModel.upcomingEvents.isEmpty {
                emptyUpcomingCard
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.upcomingEvents) { event in
                            NavigationLink(value: AppRoute.eventDetail(event.persistentModelID)) {
                                upcomingEventCard(event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
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
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                if let data = event.coverImage, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 160)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: eventGradientColors(event.type),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 180, height: 160)
                    .overlay {
                        Image(systemName: event.type.iconName)
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Text(event.type.displayName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.bgSurface.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(8)
            }
            .frame(width: 180, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))

            // Event info
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(formatEventDate(event.date))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
        .frame(width: 180)
        .contentShape(Rectangle())
    }

    // MARK: - Recent Records Section

    private var recentRecordsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(
                title: String(localized: "home.recentRecords")
            )

            if viewModel.recentRecords.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "record.list.empty"),
                    actionTitle: String(localized: "home.addRecord"),
                    action: {
                        sheetRoute = .addRecord(direction: nil, contactID: nil)
                    }
                )
                .accessibilityIdentifier("home.addRecordButton")
                .frame(height: 200)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.recentRecords) { record in
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
            return [DesignSystem.Colors.primary.opacity(0.3), DesignSystem.Colors.primary.opacity(0.1)]
        case .birthday, .longevity:
            return [DesignSystem.Colors.accentGold.opacity(0.3), DesignSystem.Colors.accentGold.opacity(0.1)]
        case .education, .promotion:
            return [DesignSystem.Colors.primary.opacity(0.2), DesignSystem.Colors.accentGold.opacity(0.15)]
        case .funeral, .visit:
            return [DesignSystem.Colors.textSecondary.opacity(0.2), DesignSystem.Colors.textSecondary.opacity(0.1)]
        case .festival:
            return [DesignSystem.Colors.primary.opacity(0.25), DesignSystem.Colors.accentGold.opacity(0.2)]
        case .property, .business:
            return [DesignSystem.Colors.accentGold.opacity(0.25), DesignSystem.Colors.primary.opacity(0.15)]
        case .birth:
            return [DesignSystem.Colors.primary.opacity(0.2), DesignSystem.Colors.primary.opacity(0.08)]
        case .other:
            return [DesignSystem.Colors.textSecondary.opacity(0.15), DesignSystem.Colors.bgCard]
        }
    }

    private func eventTypeIcon(_ type: EventType) -> (name: String, color: Color) {
        (type.iconName, DesignSystem.Colors.primary)
    }

    @ViewBuilder
    private func sheetContent(for route: SheetRoute) -> some View {
        switch route {
        case .addRecord(let direction, let contactID):
            NavigationStack {
                AddRecordView(direction: direction, contactID: contactID)
            }
        case .addContact:
            NavigationStack {
                AddContactView()
            }
        case .addEvent:
            NavigationStack {
                AddEventView()
            }
        case .editContact(let contactID):
            NavigationStack {
                AddContactView(contactID: contactID)
            }
        case .editEvent(let eventID):
            NavigationStack {
                AddEventView(eventID: eventID)
            }
        case .editRecord(let recordID):
            NavigationStack {
                AddRecordView(recordID: recordID)
            }
        case .returnGift(let recordID):
            NavigationStack {
                ReturnGiftSheet(recordID: recordID)
            }
        case .ocrImport:
            OCRImportView()
        case .proMembership:
            NavigationStack {
                ProMembershipView()
            }
        }
    }
}

private func makeHomePreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext

    let c1 = Contact(name: "张三", relation: "同事")
    let c2 = Contact(name: "李四", relation: "朋友")
    let c3 = Contact(name: "王五", relation: "亲戚")
    [c1, c2, c3].forEach { ctx.insert($0) }

    let cal = Calendar.current
    let e1 = Event(name: "表哥的婚礼", type: .wedding, date: cal.date(byAdding: .day, value: 3, to: .now)!, location: "北京")
    let e2 = Event(name: "小李的30岁生日", type: .birthday, date: cal.date(byAdding: .day, value: 7, to: .now)!, location: "上海")
    let e3 = Event(name: "硕士毕业", type: .education, date: cal.date(byAdding: .day, value: 14, to: .now)!, location: "广州")
    [e1, e2, e3].forEach { ctx.insert($0) }

    let r1 = Record(contact: c1, event: e1, amount: 500, direction: .given, paymentMethod: .wechat, date: .now)
    let r2 = Record(contact: c2, event: e2, amount: 200, direction: .given, paymentMethod: .cash, date: cal.date(byAdding: .day, value: -1, to: .now)!)
    let r3 = Record(contact: c3, event: e1, amount: 350, direction: .given, paymentMethod: .alipay, date: cal.date(byAdding: .day, value: -3, to: .now)!)
    let r4 = Record(contact: c1, event: e2, amount: 600, direction: .received, paymentMethod: .wechat, date: cal.date(byAdding: .day, value: -10, to: .now)!)
    [r1, r2, r3, r4].forEach { ctx.insert($0) }

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
