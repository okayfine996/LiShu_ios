import SwiftUI
import SwiftData

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
                        heroCard(event)
                        summaryCards(event)
                        if !viewModel.relatedContacts.isEmpty {
                            contactsSection
                        }
                        recordsSection(event)
                        if !event.note.isEmpty {
                            notesSection(event)
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

    // MARK: - Summary Cards (2-column)

    private func summaryCards(_ event: Event) -> some View {
        HStack(spacing: 12) {
            // Given amount card
            VStack(spacing: 8) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: 32, height: 32)
                    .background(DesignSystem.Colors.primary.opacity(0.12))
                    .clipShape(Circle())

                Text(String(localized: "event.detail.totalGiven"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text("\u{00A5}" + String(format: "%.0f", viewModel.totalGiven))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))

            // Received amount card
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.left")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignSystem.Colors.accentGold)
                    .frame(width: 32, height: 32)
                    .background(DesignSystem.Colors.accentGold.opacity(0.12))
                    .clipShape(Circle())

                Text(String(localized: "event.detail.totalReceived"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text("\u{00A5}" + String(format: "%.0f", viewModel.totalReceived))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.accentGold)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        }
    }

    // MARK: - Related Contacts Section

    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "event.detail.relatedContacts"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.relatedContacts) { contact in
                        NavigationLink(value: AppRoute.contactDetail(contact.persistentModelID)) {
                            VStack(spacing: 6) {
                                AvatarView(imageData: contact.avatar, name: contact.name)

                                Text(contact.name)
                                    .font(DesignSystem.Typography.small)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(width: 64)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    // MARK: - Records Section

    private func recordsSection(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "event.detail.relatedRecords"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(String(format: String(localized: "event.list.recordCount"), (event.records ?? []).count))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            if (event.records ?? []).isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "event.detail.noRecords")
                )
                .frame(height: 200)
            } else {
                let sortedRecords = (event.records ?? []).sorted(by: { $0.date > $1.date })
                VStack(spacing: 0) {
                    ForEach(sortedRecords) { record in
                        NavigationLink(value: AppRoute.recordDetail(record.persistentModelID)) {
                            RecordRow(
                                avatar: record.contact?.avatar,
                                contactName: record.contact?.name ?? "",
                                eventName: event.name,
                                amount: record.resolvedDisplayAmount,
                                direction: record.direction,
                                date: record.date,
                                recordType: record.recordType,
                                favorDescription: record.resolvedDescription,
                                paymentMethodRaw: record.resolvedPaymentMethod.rawValue,
                                kvData: record.kvData,
                                contextTag: record.contextTag,
                                returnedAmount: record.resolvedReturnedAmount
                            )
                        }
                        .buttonStyle(.plain)

                        if record.persistentModelID != sortedRecords.last?.persistentModelID {
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

    // MARK: - Cover Image

    private func eventCoverImage(_ data: Data) -> some View {
        Group {
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
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
        case .addRecord(let direction, let contactID):
            NavigationStack {
                AddRecordView(direction: direction, contactID: contactID)
            }
        case .editEvent(let eID):
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
            date: cal.date(byAdding: .day, value: 3, to: .now)!,
            location: "北京国贸大酒店",
            note: "提前一天到达，需要帮忙布置场地。记得带红包和礼物。"
        )
        modelContext.insert(event)

        let r1 = Record.makeMonetaryRecord(contact: c1, event: event, amount: 1000, direction: .given, paymentMethod: .wechat, date: cal.date(byAdding: .day, value: -5, to: .now)!)
        let r2 = Record.makeMonetaryRecord(contact: c2, event: event, amount: 500, direction: .received, paymentMethod: .cash, date: cal.date(byAdding: .day, value: -3, to: .now)!)
        let r3 = Record.makeMonetaryRecord(contact: c3, event: event, amount: 800, direction: .given, paymentMethod: .alipay, date: cal.date(byAdding: .day, value: -1, to: .now)!)
        [r1, r2, r3].forEach { modelContext.insert($0) }

        try? modelContext.save()
        eventID = event.persistentModelID
    }
}

#Preview {
    EventDetailPreview()
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
