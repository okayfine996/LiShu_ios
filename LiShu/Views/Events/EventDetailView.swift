import SwiftData
import SwiftUI

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = EventDetailViewModel()
    @State private var sheetRoute: SheetRoute?

    let eventID: PersistentIdentifier

    var body: some View {
        Group {
            if let event = viewModel.event {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if let coverData = event.coverImage {
                            eventCoverImage(coverData)
                        }
                        if event.hostMode == .host {
                            hostLedgerContent(event)
                        } else {
                            standardEventContent(event)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(viewModel.event?.name ?? String(localized: "event.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if viewModel.event?.hostMode == .host {
                        Button {
                            sheetRoute = .addLedgerReceipt(eventID: eventID)
                        } label: {
                            Label(String(localized: "event.ledger.primaryAction"), systemImage: "plus.circle")
                        }
                    }
                    Button {
                        sheetRoute = .editEvent(eventID)
                    } label: {
                        Label(String(localized: "common.edit"), systemImage: "pencil")
                    }
                    if (viewModel.event?.records ?? []).isEmpty {
                        Button(role: .destructive) {
                            viewModel.isShowingDeleteAlert = true
                        } label: {
                            Label(String(localized: "common.delete"), systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .onAppear {
            viewModel.load(id: eventID, context: modelContext)
        }
        .alert(String(localized: "event.detail.deleteConfirm"), isPresented: $viewModel.isShowingDeleteAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.delete"), role: .destructive) {
                if viewModel.deleteEvent(context: modelContext) {
                    dismiss()
                } else {
                    viewModel.isShowingDeleteBlockedAlert = true
                }
            }
        }
        .alert(String(localized: "event.detail.deleteBlocked"), isPresented: $viewModel.isShowingDeleteBlockedAlert) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(String(localized: "event.detail.deleteBlockedMessage"))
        }
        .sheet(item: $sheetRoute) { route in
            sheetContent(for: route)
        }
        .onChange(of: sheetRoute) { _, newValue in
            if newValue == nil {
                viewModel.load(id: eventID, context: modelContext)
            }
        }
    }

    // MARK: - Hero Card

    private func hostLedgerContent(_ event: Event) -> some View {
        Group {
            heroCard(event)
            ledgerSummaryCards
            ledgerRecordsSection(event)
            if !event.note.isEmpty {
                notesSection(event)
            }
        }
    }

    private func standardEventContent(_ event: Event) -> some View {
        Group {
            heroCard(event)
            primaryRecordSection(event)
            if !event.note.isEmpty {
                notesSection(event)
            }
        }
    }

    private func heroCard(_ event: Event) -> some View {
        VStack(spacing: 12) {
            Image(systemName: event.type.iconName)
                .font(.system(size: 28))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 72, height: 72)
                .background(DesignSystem.Colors.bgIconSubtle)
                .clipShape(Circle())

            // Event name
            Text(event.name)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // Type + date
            HStack(spacing: 8) {
                Text(event.type.displayName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(DesignSystem.Colors.primary.opacity(0.12))
                    .clipShape(Capsule())

                Text("\u{00B7}")
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                Text(viewModel.formattedDate)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            if event.hostMode == .host {
                Text(String(localized: "event.ledger.hostBadge"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.primary.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Location
            if !event.location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12))
                    Text(event.location)
                        .font(DesignSystem.Typography.small)
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Countdown badge (if upcoming)
            if viewModel.isUpcoming {
                if let days = viewModel.daysUntilEvent {
                    Text(days == 0 ? String(localized: "home.today") : String(format: String(localized: "event.detail.countdown"), days))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DesignSystem.Colors.primary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private var ledgerSummaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ledgerSummaryCard(
                    icon: "banknote",
                    title: String(localized: "event.ledger.totalAmount"),
                    value: "¥" + String(format: "%.0f", viewModel.totalReceived),
                    tint: DesignSystem.Colors.primary
                )
                ledgerSummaryCard(
                    icon: "person.2.fill",
                    title: String(localized: "event.ledger.totalCount"),
                    value: String(format: String(localized: "event.ledger.countValue"), viewModel.receivedRecordCount),
                    tint: DesignSystem.Colors.accentGold
                )
            }

            HStack(spacing: 12) {
                ledgerSummaryCard(
                    icon: "arrow.up.forward.circle",
                    title: String(localized: "event.ledger.maxAmount"),
                    value: "¥" + String(format: "%.0f", viewModel.largestReceivedAmount),
                    tint: DesignSystem.Colors.primary
                )
                ledgerSummaryCard(
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

    private func ledgerSummaryCard(icon: String, title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
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

    // MARK: - Ledger Records Section

    private func ledgerRecordsSection(_ event: Event) -> some View {
        let displayedRecords = viewModel.receivedRecords
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "event.ledger.allRecords"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(String(format: String(localized: "event.list.recordCount"), displayedRecords.count))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            if displayedRecords.isEmpty {
                EmptyStateView(
                    icon: "book.closed",
                    message: String(localized: "event.ledger.empty"),
                    actionTitle: String(localized: "event.ledger.primaryAction"),
                    action: {
                        sheetRoute = .addLedgerReceipt(eventID: event.persistentModelID)
                    }
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 0) {
                    ForEach(displayedRecords) { record in
                        NavigationLink {
                            RecordDetailView(recordID: record.persistentModelID)
                        } label: {
                            RecordRow(record: record)
                        }
                        .buttonStyle(.plain)

                        if record.persistentModelID != displayedRecords.last?.persistentModelID {
                            Divider()
                                .foregroundStyle(DesignSystem.Colors.separator)
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }
        }
    }

    // MARK: - Primary Record Section

    private func primaryRecordSection(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "event.detail.primaryRecord"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if let record = viewModel.primaryRecord {
                NavigationLink {
                    RecordDetailView(recordID: record.persistentModelID)
                } label: {
                    primaryRecordCard(record)
                }
                .buttonStyle(.plain)
            } else {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "event.detail.noPrimaryRecord"),
                    actionTitle: String(localized: "event.detail.addRecord"),
                    action: {
                        sheetRoute = .addRecord(direction: .given, contactID: nil, eventID: event.persistentModelID)
                    }
                )
                .frame(height: 180)
            }
        }
    }

    /// 普通事件默认是“我去参加别人场合”的语义，所以这里只突出一条主记录摘要，
    /// 而不是继续展示多联系人、多记录列表的礼簿式结构。
    private func primaryRecordCard(_ record: Record) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: record.recordType.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Colors.bgIconSubtle)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryRecordTitle(for: record))
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text(primaryRecordSubtitle(for: record))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            VStack(spacing: 10) {
                primaryRecordTypeDetails(record)
                primaryRecordMetaRow(
                    label: String(localized: "record.add.date"),
                    value: primaryRecordDateText(record.date)
                )
                primaryRecordMetaRow(
                    label: String(localized: "record.detail.relationshipWeight"),
                    value: record.relationshipWeight.displayName
                )

                if !record.note.isEmpty {
                    primaryRecordMetaRow(
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
    private func primaryRecordTypeDetails(_ record: Record) -> some View {
        // 不同记录类型关注的信息完全不同，这里按类型拼摘要，
        // 避免把礼品、帮忙、宴请都硬套成“金额卡片”。
        switch record.resolvedTypeData {
        case let .monetary(data):
            primaryRecordMetaRow(
                label: String(localized: "record.detail.giftAmount"),
                value: formatCurrency(data.amount)
            )
            primaryRecordMetaRow(
                label: String(localized: "record.add.paymentMethod"),
                value: paymentMethodText(record.resolvedPaymentMethod)
            )
        case let .gift(data):
            primaryRecordMetaRow(
                label: String(localized: "record.detail.giftName"),
                value: data.giftName
            )
            if let estimatedValue = data.estimatedValue, estimatedValue > 0 {
                primaryRecordMetaRow(
                    label: String(localized: "record.detail.estimatedValue"),
                    value: formatCurrency(estimatedValue)
                )
            }
        case let .favor(data):
            if !data.description.isEmpty {
                primaryRecordMetaRow(
                    label: record.recordType.displayName,
                    value: data.description
                )
            }
        case let .banquet(data):
            if !data.location.isEmpty {
                primaryRecordMetaRow(
                    label: String(localized: "record.add.banquet.location"),
                    value: data.location
                )
            }
            if !data.attendeeList.isEmpty {
                primaryRecordMetaRow(
                    label: String(localized: "record.add.banquet.attendees"),
                    value: data.attendeeList
                )
            }
            if !data.extraCostNotes.isEmpty {
                primaryRecordMetaRow(
                    label: String(localized: "record.add.banquet.extraCostNotes"),
                    value: data.extraCostNotes
                )
            }
        }
    }

    private func primaryRecordMetaRow(label: String, value: String) -> some View {
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

    private func primaryRecordTitle(for record: Record) -> String {
        // 标题优先使用用户真正录入的内容，让卡片读起来更像“这次人情的摘要”。
        switch record.resolvedTypeData {
        case .monetary:
            return String(localized: "event.detail.monetaryRecordTitle")
        case let .gift(data):
            return data.giftName.isEmpty ? record.recordType.displayName : data.giftName
        case let .favor(data):
            return data.description.isEmpty ? record.recordType.displayName : data.description
        case let .banquet(data):
            if !data.location.isEmpty {
                return data.location
            }
            if !data.attendeeList.isEmpty {
                return data.attendeeList
            }
            return record.recordType.displayName
        }
    }

    private func primaryRecordSubtitle(for record: Record) -> String {
        let components: [String] = [
            record.direction == .given
                ? String(localized: "record.detail.directionSent")
                : String(localized: "record.detail.directionReceived"),
            record.contact?.name,
        ]
        .compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }

        return components.joined(separator: " · ")
    }

    private func primaryRecordDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }

    private func paymentMethodText(_ method: PaymentMethod) -> String {
        switch method {
        case .cash:
            String(localized: "payment.cash")
        case .wechat:
            String(localized: "payment.wechat")
        case .alipay:
            String(localized: "payment.alipay")
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
        return "\u{00A5}" + formatted
    }

    // MARK: - Cover Image

    private func eventCoverImage(_ data: Data) -> some View {
        Group {
            if !data.isEmpty {
                DecodedImageView(data: data, maxPixelSize: ImagePipeline.Preset.detailHeroMaxPixelSize)
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "event.detail.notes"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Text(event.note)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    // MARK: - Sheet Content

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
        case let .editEvent(eID):
            NavigationStack {
                AddEventView(eventID: eID)
            }
        default:
            EmptyView()
        }
    }
}

private struct EventDetailPreview: View {
    @Environment(\.modelContext) private var modelContext
    @State private var eventID: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            if let eventID {
                EventDetailView(eventID: eventID)
            } else {
                ProgressView()
            }
        }
        .onAppear { seedData() }
    }

    private func seedData() {
        let cal = Calendar.current

        let c1 = Contact(name: "张三", relation: "同事")
        let c2 = Contact(name: "李四", relation: "朋友")
        let c3 = Contact(name: "王五", relation: "亲戚")
        [c1, c2, c3].forEach { modelContext.insert($0) }

        let event = Event(
            name: "张三的婚礼",
            type: .wedding,
            date: cal.liShuDateByAddingDays(3),
            location: "北京国贸大酒店",
            note: "提前一天到达，需要帮忙布置场地。记得带红包和礼物。"
        )
        modelContext.insert(event)

        let r1 = Record.makeMonetaryRecord(
            contact: c1,
            event: event,
            amount: 1000,
            direction: .given,
            paymentMethod: .wechat,
            date: cal.liShuDateByAddingDays(-5)
        )
        let r2 = Record.makeMonetaryRecord(
            contact: c2,
            event: event,
            amount: 500,
            direction: .received,
            paymentMethod: .cash,
            date: cal.liShuDateByAddingDays(-3)
        )
        let r3 = Record.makeMonetaryRecord(
            contact: c3,
            event: event,
            amount: 800,
            direction: .given,
            paymentMethod: .alipay,
            date: cal.liShuDateByAddingDays(-1)
        )
        [r1, r2, r3].forEach { modelContext.insert($0) }

        try? modelContext.save()
        eventID = event.persistentModelID
    }
}

#Preview {
    EventDetailPreview()
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
