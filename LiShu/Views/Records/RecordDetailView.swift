import SwiftUI
import SwiftData

struct RecordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RecordDetailViewModel()
    @State private var sheetRoute: SheetRoute?
    @State private var fullScreenPhotoItem: PhotoViewItem?

    let recordID: PersistentIdentifier

    var body: some View {
        Group {
            if let record = viewModel.record {
                ZStack(alignment: .bottom) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            profileSection(record)
                            amountGrid(record)
                            contextSummaryCard(record)
                            favorDescriptionSection(record)
                            detailsCard(record)
                            notesSection(record)
                            photosSection(record)
                            contactHistorySection(record)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .padding(.bottom, 80)
                    }

                    bottomReturnButton
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "record.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        sheetRoute = .editRecord(recordID)
                    } label: {
                        Label(String(localized: "common.edit"), systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        viewModel.isShowingDeleteAlert = true
                    } label: {
                        Label(String(localized: "common.delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .onAppear {
            viewModel.load(id: recordID, context: modelContext)
        }
        .alert(String(localized: "record.detail.deleteConfirm"), isPresented: $viewModel.isShowingDeleteAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.delete"), role: .destructive) {
                if viewModel.deleteRecord(context: modelContext) {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingReturnSheet) {
            returnGiftSheet
        }
        .sheet(item: $sheetRoute) { route in
            if case .editRecord(let rID) = route {
                NavigationStack {
                    AddRecordView(recordID: rID)
                }
            }
        }
        .fullScreenCover(item: $fullScreenPhotoItem) { item in
            FullScreenPhotoView(imageData: item.data) {
                fullScreenPhotoItem = nil
            }
        }
        .onChange(of: sheetRoute) { _, newValue in
            if newValue == nil {
                viewModel.load(id: recordID, context: modelContext)
            }
        }
    }

    // MARK: - Profile Section

    private func profileSection(_ record: Record) -> some View {
        VStack(spacing: 12) {
            AvatarView(imageData: record.contact?.avatar, name: record.contact?.name ?? "", size: 80)

            Text(record.contact?.name ?? "")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            let subtitle = [
                record.contact?.relation ?? "",
                record.contextDisplayName
            ].filter { !$0.isEmpty }.joined(separator: " · ")

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            HStack(spacing: 8) {
                StatusBadge(status: record.status, direction: record.direction)

                HStack(spacing: 4) {
                    Image(systemName: record.direction == .given ? "arrow.up.right" : "arrow.down.left")
                        .font(.system(size: 10))
                    Text(viewModel.directionLabel)
                        .font(DesignSystem.Typography.small)
                }
                .foregroundStyle(directionColor(record.direction))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(directionColor(record.direction).opacity(0.12))
                .clipShape(Capsule())

                if !record.isMonetary {
                    HStack(spacing: 4) {
                        Text(record.recordType.iconEmoji)
                            .font(DesignSystem.Typography.small)
                        Text(record.recordType.displayName)
                            .font(DesignSystem.Typography.small)
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.bgTag)
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    // MARK: - Amount Grid

    @ViewBuilder
    private func amountGrid(_ record: Record) -> some View {
        if record.isMonetary {
            HStack(spacing: 8) {
                amountCell(
                    label: String(localized: "record.detail.giftAmount"),
                    value: formatAmount(record.monetaryAmount),
                    highlighted: false
                )
                amountCell(
                    label: String(localized: "record.detail.returnAmount"),
                    value: formatAmount(record.returnedAmount),
                    highlighted: false
                )
                amountCell(
                    label: String(localized: "record.detail.actualDebt"),
                    value: formatAmount(record.outstandingAmount),
                    highlighted: true
                )
            }
        } else if record.resolvedDisplayAmount > 0 {
            HStack(spacing: 8) {
                amountCell(
                    label: String(localized: "record.detail.giftAmount"),
                    value: formatAmount(record.resolvedDisplayAmount),
                    highlighted: false
                )
            }
        }
    }

    private func amountCell(label: String, value: String, highlighted: Bool) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(highlighted ? .white.opacity(0.8) : DesignSystem.Colors.textSecondary)
            Text(value)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(highlighted ? .white : DesignSystem.Colors.textPrimary)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(highlighted ? DesignSystem.Colors.primary : DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    // MARK: - Type Specific Detail Section

    private func contextSummaryCard(_ record: Record) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: record.isDailyInteraction ? "bubble.left.and.bubble.right" : "calendar")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 36, height: 36)
                .background(DesignSystem.Colors.bgIconSubtle)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(record.isDailyInteraction ? String(localized: "record.detail.context.dailyTitle") : String(localized: "record.detail.context.eventTitle"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(record.isDailyInteraction ? String(localized: "record.detail.context.dailyName") : record.contextDisplayName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .fontWeight(.semibold)

                Text(contextSummaryMessage(record))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    @ViewBuilder
    private func favorDescriptionSection(_ record: Record) -> some View {
        if record.isMonetary { EmptyView() }
        else {
            let typeData = record.resolvedTypeData
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Text(record.recordType.iconEmoji)
                        .font(DesignSystem.Typography.caption)
                    Text(record.recordType.displayName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.semibold)
                }

                switch typeData {
                case .gift(let d):
                    LabeledContent(String(localized: "record.detail.giftName")) {
                        Text(d.giftName)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    if let v = d.estimatedValue, v > 0 {
                        LabeledContent(String(localized: "record.detail.estimatedValue")) {
                            Text(formatAmount(v))
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                case .banquet(let d):
                    if !d.location.isEmpty {
                        LabeledContent(String(localized: "record.add.banquet.location")) {
                            Text(d.location)
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    if !d.attendeeList.isEmpty {
                        LabeledContent(String(localized: "record.add.banquet.attendees")) {
                            Text(d.attendeeList)
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    if !d.extraCostNotes.isEmpty {
                        LabeledContent(String(localized: "record.add.banquet.extraCostNotes")) {
                            Text(d.extraCostNotes)
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                default:
                    if !record.resolvedDescription.isEmpty {
                        Text(record.resolvedDescription)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineSpacing(4)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    // MARK: - Details Card

    private func detailsCard(_ record: Record) -> some View {
        VStack(spacing: 0) {
            infoRow(
                icon: "doc.text",
                label: String(localized: "record.add.recordType"),
                value: record.recordType.displayName
            )
            Divider().foregroundStyle(DesignSystem.Colors.separator).padding(.leading, 56)
            infoRow(
                icon: "slider.horizontal.3",
                label: String(localized: "record.detail.relationshipWeight"),
                value: record.relationshipWeight.displayName
            )
            Divider().foregroundStyle(DesignSystem.Colors.separator).padding(.leading, 56)
            if record.isMonetary {
                infoRow(
                    icon: "creditcard",
                    label: String(localized: "record.add.paymentMethod"),
                    value: viewModel.paymentMethodName
                )
                Divider().foregroundStyle(DesignSystem.Colors.separator).padding(.leading, 56)
            }
            infoRow(
                icon: "calendar",
                label: String(localized: "record.add.context"),
                value: record.contextDisplayName
            )
            Divider().foregroundStyle(DesignSystem.Colors.separator).padding(.leading, 56)
            infoRow(
                icon: "calendar.badge.clock",
                label: String(localized: "record.add.date"),
                value: viewModel.formattedDate
            )
            if let eventTypeName = record.event?.type.displayName {
                Divider().foregroundStyle(DesignSystem.Colors.separator).padding(.leading, 56)
                infoRow(
                    icon: "tag",
                    label: String(localized: "record.add.eventType"),
                    value: eventTypeName
                )
            }
        }
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 32, height: 32)
                .background(DesignSystem.Colors.bgIconSubtle)
                .clipShape(Circle())

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func contextSummaryMessage(_ record: Record) -> String {
        if let event = record.event {
            return String(format: String(localized: "record.detail.context.eventMessage"), event.type.displayName)
        }
        return String(localized: "record.detail.context.dailyMessage")
    }

    // MARK: - Notes Section

    @ViewBuilder
    private func notesSection(_ record: Record) -> some View {
        if !record.note.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignSystem.Colors.primary)
                    Text(String(localized: "record.detail.notesSection"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.semibold)
                }

                Text(record.note)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineSpacing(4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    // MARK: - Photos Section

    @ViewBuilder
    private func photosSection(_ record: Record) -> some View {
        if !(record.photos ?? []).isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "record.detail.photos"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)
                    .padding(.leading, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach((record.photos ?? []).sorted(by: { $0.createdAt < $1.createdAt })) { photo in
                            Button {
                                fullScreenPhotoItem = PhotoViewItem(data: photo.imageData)
                            } label: {
                                recordPhotoThumbnail(imageData: photo.imageData)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                }
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }
        }
    }

    private func recordPhotoThumbnail(imageData: Data) -> some View {
        Group {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 80, height: 80)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    // MARK: - Contact History Section

    @ViewBuilder
    private func contactHistorySection(_ record: Record) -> some View {
        if let contact = record.contact {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(format: String(localized: "record.detail.contactHistory"), contact.name))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)
                .padding(.leading, 4)

            NavigationLink(value: AppRoute.contactDetail(contact.persistentModelID)) {
                HStack(spacing: 12) {
                    AvatarView(imageData: contact.avatar, name: contact.name, size: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(String(localized: "record.detail.historySummary"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .fontWeight(.semibold)

                        Text(String(
                            format: String(localized: "record.detail.historyDetail"),
                            viewModel.contactRecordCount,
                            formatAmount(viewModel.contactNetAmount)
                        ))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    Spacer()

                    Text(String(localized: "record.detail.viewAll"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.primary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .padding(14)
                .contentShape(Rectangle())
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }
            .buttonStyle(.plain)
        }
        }
    }

    // MARK: - Bottom Return Button

    @ViewBuilder
    private var bottomReturnButton: some View {
        if viewModel.shouldShowReturnButton {
            Button {
                viewModel.isShowingReturnSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text(String(localized: "record.detail.returnGift"))
                        .font(DesignSystem.Typography.body)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Return Gift Sheet

    private var returnGiftSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(String(localized: "record.detail.returnGiftTitle"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if let record = viewModel.record {
                    VStack(spacing: 8) {
                        HStack {
                            Text(String(localized: "record.detail.currentAmount"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            Spacer()
                            Text(formatAmount(record.monetaryAmount))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                .fontWeight(.medium)
                        }

                        if record.returnedAmount > 0 {
                            HStack {
                                Text(String(localized: "record.detail.alreadyReturned"))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                Spacer()
                                Text(formatAmount(record.returnedAmount))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.accentGold)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding(14)
                    .background(DesignSystem.Colors.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "record.detail.returnAmountLabel"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        Text("¥")
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        TextField("0", text: $viewModel.returnedAmountText)
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .keyboardType(.decimalPad)
                    }
                    .padding(12)
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                }

                Button {
                    if viewModel.saveReturn(context: modelContext) {
                        viewModel.isShowingReturnSheet = false
                    }
                } label: {
                    Text(String(localized: "record.detail.confirmReturn"))
                }
                .buttonStyle(PrimaryButtonStyle())

                Spacer()
            }
            .padding(20)
            .background(DesignSystem.Colors.bgPage)
            .navigationTitle(String(localized: "record.detail.returnGift"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.cancel")) {
                        viewModel.returnedAmountText = ""
                        viewModel.isShowingReturnSheet = false
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private func directionColor(_ direction: RecordDirection) -> Color {
        direction == .received
            ? DesignSystem.Colors.accentGold
            : DesignSystem.Colors.primary
    }

    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
        return "¥" + formatted
    }
}

// MARK: - Photo View Helpers

private struct PhotoViewItem: Identifiable {
    let id = UUID()
    let data: Data
}

private struct FullScreenPhotoView: View {
    let imageData: Data
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            }
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(DesignSystem.Typography.title1)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .background(Circle().fill(DesignSystem.Colors.bgSurface.opacity(0.8)))
            }
            .padding(16)
        }
        .background(DesignSystem.Colors.overlayDark)
    }
}

private struct RecordDetailPreview: View {
    @Environment(\.modelContext) private var modelContext
    @State private var recordID: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            if let recordID {
                RecordDetailView(recordID: recordID)
            } else {
                ProgressView()
            }
        }
        .onAppear { seedData() }
    }

    private func seedData() {
        let cal = Calendar.current

        let contact = Contact(name: "张三", relation: "朋友")
        modelContext.insert(contact)

        let event = Event(name: "结婚大礼", type: .wedding, date: cal.date(byAdding: .day, value: -60, to: .now)!)
        modelContext.insert(event)

        let record = Record(
            contact: contact,
            event: event,
            amount: 1000,
            direction: .given,
            paymentMethod: .wechat,
            returnedAmount: 200,
            note: "记得发送感谢短信。这是一个非常慷慨的婚礼礼物。下次见面记得带伴手礼。",
            date: cal.date(byAdding: .day, value: -60, to: .now)!
        )
        modelContext.insert(record)

        let event2 = Event(name: "春节聚会", type: .festival, date: cal.date(byAdding: .month, value: -3, to: .now)!)
        modelContext.insert(event2)
        let r2 = Record(contact: contact, event: event2, amount: 500, direction: .received, paymentMethod: .cash, date: cal.date(byAdding: .month, value: -3, to: .now)!)
        let r3 = Record(contact: contact, event: event, amount: 300, direction: .received, paymentMethod: .alipay, date: cal.date(byAdding: .day, value: -30, to: .now)!)
        [r2, r3].forEach { modelContext.insert($0) }

        try? modelContext.save()
        recordID = record.persistentModelID
    }
}

#Preview {
    RecordDetailPreview()
        .modelContainer(for: [Contact.self, Record.self, Event.self, RecordPhoto.self], inMemory: true)
}
