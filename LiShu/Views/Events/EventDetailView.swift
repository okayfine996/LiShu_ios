import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = EventDetailViewModel()
    @State private var pendingDeleteRecord: Record?
    @State private var sheetRoute: SheetRoute?
    @State private var ledgerImportPreviewViewModel: LedgerCSVImportPreviewViewModel?
    @State private var ledgerExportPreviewViewModel: LedgerCSVExportPreviewViewModel?
    @State private var showLedgerCSVImporter = false
    @State private var showLedgerImportPreview = false
    @State private var showLedgerExportPreview = false
    @State private var ledgerShareURL: URL?
    @State private var ledgerCSVError: String?
    @State private var isPreparingLedgerCSV = false
    @State private var showLegacyAnomalyList = false

    let eventID: PersistentIdentifier

    var body: some View {
        Group {
            if let event = viewModel.event {
                if event.hostMode == .host {
                    hostLedgerList(event)
                } else {
                    standardEventScroll(event)
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
                        Button {
                            sheetRoute = .ocrImport(eventID: eventID)
                        } label: {
                            Label(String(localized: "ocr.source.title"), systemImage: "doc.viewfinder")
                        }
                        Button {
                            guard !isPreparingLedgerCSV else { return }
                            showLedgerCSVImporter = true
                        } label: {
                            Label(String(localized: "event.ledger.importCSV"), systemImage: "square.and.arrow.down")
                        }
                        Button {
                            prepareLedgerExportPreview()
                        } label: {
                            Label(String(localized: "event.ledger.exportCSV"), systemImage: "square.and.arrow.up")
                        }
                        Button {
                            downloadLedgerTemplate()
                        } label: {
                            Label(String(localized: "event.ledger.downloadTemplate"), systemImage: "arrow.down.doc")
                        }
                    }
                    Button {
                        sheetRoute = .editEvent(eventID)
                    } label: {
                        Label(String(localized: "common.edit"), systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        viewModel.isShowingDeleteAlert = true
                    } label: {
                        Label(String(localized: "common.delete"), systemImage: "trash")
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
                }
            }
        } message: {
            Text(String(localized: "event.detail.deleteConfirmMessage"))
        }
        .alert(String(localized: "common.error"), isPresented: Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )) {
            Button(String(localized: "common.ok")) {
                viewModel.deleteError = nil
            }
        } message: {
            if let message = viewModel.deleteError {
                Text(message)
            }
        }
        .alert(
            String(localized: "record.detail.deleteConfirm"),
            isPresented: Binding(
                get: { pendingDeleteRecord != nil },
                set: { if !$0 { pendingDeleteRecord = nil } }
            )
        ) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                pendingDeleteRecord = nil
            }
            Button(String(localized: "common.delete"), role: .destructive) {
                guard let pendingDeleteRecord else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    _ = viewModel.deleteRecord(pendingDeleteRecord, context: modelContext)
                }
                self.pendingDeleteRecord = nil
            }
        }
        .sheet(item: $sheetRoute) { route in
            sheetContent(for: route)
        }
        .sheet(item: Binding(
            get: { ledgerShareURL.map { EventDetailShareableFile(id: $0.absoluteString, url: $0) } },
            set: {
                if let url = ledgerShareURL, $0 == nil {
                    try? FileManager.default.removeItem(at: url)
                }
                ledgerShareURL = $0?.url
            }
        )) { item in
            ShareSheet(url: item.url) {
                ledgerShareURL = nil
                try? FileManager.default.removeItem(at: item.url)
            }
        }
        .navigationDestination(isPresented: $showLedgerImportPreview) {
            if let ledgerImportPreviewViewModel {
                LedgerCSVImportPreviewView(viewModel: ledgerImportPreviewViewModel) { result in
                    handleCompletedLedgerImport(result)
                }
            }
        }
        .navigationDestination(isPresented: $showLegacyAnomalyList) {
            if let event = viewModel.event {
                LegacyLedgerAnomalyListView(
                    eventName: event.name,
                    eventID: event.persistentModelID
                )
            }
        }
        .navigationDestination(isPresented: $showLedgerExportPreview) {
            if let ledgerExportPreviewViewModel {
                LedgerCSVExportPreviewView(viewModel: ledgerExportPreviewViewModel) { fileURL in
                    handleConfirmedLedgerExport(fileURL: fileURL)
                }
            }
        }
        .alert(String(localized: "common.error"), isPresented: Binding(
            get: { ledgerCSVError != nil },
            set: { if !$0 { ledgerCSVError = nil } }
        )) {
            Button(String(localized: "common.ok")) {
                ledgerCSVError = nil
            }
        } message: {
            if let ledgerCSVError {
                Text(ledgerCSVError)
            }
        }
        .overlay {
            if isPreparingLedgerCSV {
                ledgerCSVLoadingOverlay
            }
        }
        .fileImporter(
            isPresented: $showLedgerCSVImporter,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleLedgerCSVImport(result)
        }
        .onChange(of: sheetRoute) { _, newValue in
            if newValue == nil {
                viewModel.load(id: eventID, context: modelContext)
            }
        }
        .onChange(of: showLedgerImportPreview) { _, newValue in
            if !newValue {
                ledgerImportPreviewViewModel = nil
            }
        }
        .onChange(of: showLedgerExportPreview) { _, newValue in
            if !newValue {
                ledgerExportPreviewViewModel = nil
            }
        }
    }

    // MARK: - Hero Card

    private func hostLedgerList(_ event: Event) -> some View {
        List {
            if let coverData = event.coverImage {
                cardListRow {
                    eventCoverImage(coverData)
                }
            }

            cardListRow {
                heroCard(event)
            }

            if viewModel.hasLegacyLedgerAnomalies {
                cardListRow {
                    Button {
                        showLegacyAnomalyList = true
                    } label: {
                        legacyLedgerWarningBanner
                    }
                    .buttonStyle(.plain)
                }
            }

            cardListRow {
                ledgerSummaryCards
            }

            ledgerRecordsSection(event)

            if !event.note.isEmpty {
                cardListRow {
                    notesSection(event)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.bgPage)
    }

    private var legacyLedgerWarningBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.accentGold)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 12) {
                Text(
                    String(
                        format: String(localized: "event.ledger.legacyWarning %lld"),
                        Int64(viewModel.legacyLedgerAnomalyCount)
                    )
                )
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

                if !viewModel.legacyLedgerAnomalyPreviewText.isEmpty {
                    Text(viewModel.legacyLedgerAnomalyPreviewText)
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

    private func standardEventScroll(_ event: Event) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if let coverData = event.coverImage {
                    eventCoverImage(coverData)
                }
                standardEventContent(event)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
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
                .font(DesignSystem.Typography.title1)
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
                        .font(DesignSystem.Typography.small)
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

    // MARK: - Ledger Records Section

    private func ledgerRecordsSection(_ event: Event) -> some View {
        let displayedRecords = viewModel.receivedRecords
        return Section {
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
                .listRowInsets(EdgeInsets(
                    top: 0,
                    leading: DesignSystem.Spacing.pageHorizontal,
                    bottom: DesignSystem.Spacing.block,
                    trailing: DesignSystem.Spacing.pageHorizontal
                ))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(displayedRecords) { record in
                    NavigationLink {
                        RecordDetailView(recordID: record.persistentModelID)
                    } label: {
                        RecordRow(record: record)
                    }
                    .buttonStyle(.plain)
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            pendingDeleteRecord = record
                        } label: {
                            Label(String(localized: "common.delete"), systemImage: "trash")
                        }
                    }
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
        } header: {
            HStack {
                Text(String(localized: "event.ledger.allRecords"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(String(format: String(localized: "event.list.recordCount"), displayedRecords.count))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.bottom, DesignSystem.Spacing.block)
        }
        .textCase(nil)
    }

    private func cardListRow(@ViewBuilder content: () -> some View) -> some View {
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
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
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
                    .font(DesignSystem.Typography.small)
                    .fontWeight(.medium)
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
        case let .ocrImport(eventID):
            NavigationStack {
                OCRImportView(eventID: eventID)
            }
        default:
            EmptyView()
        }
    }

    private func handleLedgerCSVImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first, let event = viewModel.event else { return }
            guard !isPreparingLedgerCSV else { return }
            isPreparingLedgerCSV = true

            Task {
                do {
                    let preview = try await ExportService.previewLedgerCSVAsync(url: url, eventName: event.name)
                    await MainActor.run {
                        ledgerImportPreviewViewModel = LedgerCSVImportPreviewViewModel(
                            previewResult: preview,
                            eventID: eventID
                        )
                        showLedgerImportPreview = true
                        isPreparingLedgerCSV = false
                    }
                } catch {
                    await MainActor.run {
                        ledgerCSVError = error.localizedDescription
                        isPreparingLedgerCSV = false
                    }
                }
            }
        case let .failure(error):
            ledgerCSVError = error.localizedDescription
        }
    }

    private func prepareLedgerExportPreview() {
        guard !isPreparingLedgerCSV else { return }
        isPreparingLedgerCSV = true

        Task {
            do {
                let preview = try await ExportService.previewLedgerExportCSVAsync(
                    container: modelContext.container,
                    eventID: eventID
                )
                await MainActor.run {
                    ledgerExportPreviewViewModel = LedgerCSVExportPreviewViewModel(previewResult: preview)
                    showLedgerExportPreview = true
                    isPreparingLedgerCSV = false
                }
            } catch {
                await MainActor.run {
                    ledgerCSVError = error.localizedDescription
                    isPreparingLedgerCSV = false
                }
            }
        }
    }

    @MainActor
    private func handleCompletedLedgerImport(_: ImportResult) {
        showLedgerImportPreview = false
        viewModel.load(id: eventID, context: modelContext)
        ledgerCSVError = nil
    }

    @MainActor
    private func handleConfirmedLedgerExport(fileURL: URL) {
        showLedgerExportPreview = false
        ledgerShareURL = fileURL
    }

    private func downloadLedgerTemplate() {
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("lishu_ledger_template.csv")
            guard let data = ExportService.ledgerTemplateCSV().data(using: .utf8) else {
                ledgerCSVError = String(localized: "settings.data.export_encoding_failed")
                return
            }
            try data.write(to: fileURL, options: .atomic)
            ledgerShareURL = fileURL
        } catch {
            ledgerCSVError = error.localizedDescription
        }
    }

    private var ledgerCSVLoadingOverlay: some View {
        ZStack {
            DesignSystem.Colors.bgPage.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.block) {
                ProgressView()
                    .tint(DesignSystem.Colors.primary)

                Text(String(localized: "csv.ledger.loading"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }
}

private struct EventDetailShareableFile: Identifiable {
    let id: String
    let url: URL
}

private struct EventDetailPreview: View {
    @Environment(\.modelContext) private var modelContext
    @State private var eventID: PersistentIdentifier?
    let hostMode: EventHostMode
    var includeLegacyAnomalies: Bool = false

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
            name: hostMode == .host ? "我的婚礼礼簿" : "张三的婚礼",
            type: .wedding,
            hostMode: hostMode,
            date: cal.liShuDateByAddingDays(3),
            location: "北京国贸大酒店",
            note: "提前一天到达，需要帮忙布置场地。记得带红包和礼物。"
        )
        modelContext.insert(event)

        let r1 = Record.makeMonetaryRecord(
            contact: c1,
            event: event,
            amount: 1000,
            direction: hostMode == .host ? .received : .given,
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
            direction: hostMode == .host ? .received : .given,
            paymentMethod: .alipay,
            date: cal.liShuDateByAddingDays(-1)
        )
        [r1, r2, r3].forEach { modelContext.insert($0) }

        if includeLegacyAnomalies, hostMode == .host {
            let legacyGift = makeGiftRecord(
                contact: c1,
                event: event,
                giftName: "龙井礼盒",
                direction: .received,
                date: cal.liShuDateByAddingDays(-2)
            )
            let legacyGiven = Record.makeMonetaryRecord(
                contact: c2,
                event: event,
                amount: 300,
                direction: .given,
                paymentMethod: .cash,
                date: cal.liShuDateByAddingDays(-4)
            )
            modelContext.insert(legacyGift)
            modelContext.insert(legacyGiven)
        }

        try? modelContext.save()
        eventID = event.persistentModelID
    }

    private func makeGiftRecord(
        contact: Contact,
        event: Event,
        giftName: String,
        direction: RecordDirection,
        date: Date
    ) -> Record {
        let record = Record(
            contact: contact,
            event: event,
            direction: direction,
            date: date,
            recordType: .gift,
            relationshipWeight: .reciprocal
        )
        record.applyTypeData(.gift(GiftData(giftName: giftName, estimatedValue: 288)))
        return record
    }
}

#Preview("Standard Event") {
    EventDetailPreview(hostMode: .guest)
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}

#Preview("Host Ledger") {
    EventDetailPreview(hostMode: .host)
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}

#Preview("Host Ledger Legacy Warning") {
    EventDetailPreview(hostMode: .host, includeLegacyAnomalies: true)
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
