import SwiftUI
import SwiftData

struct ContactDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let contactID: PersistentIdentifier

    @State private var viewModel = ContactDetailViewModel()
    @State private var presentedSheet: SheetRoute?

    private let statColumns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 2
    )

    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            if let contact = viewModel.contact {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileSection(contact)
                        statsSection(contact)
                        personalInfoSection(contact)
                        recordsSection(contact)
                    }
                    .padding(.bottom, 24)
                }
            } else if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "contact.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        presentedSheet = .editContact(contactID)
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
        .sheet(item: $presentedSheet) { route in
            switch route {
            case .addRecord(let direction, let contactID):
                NavigationStack {
                    AddRecordView(direction: direction, contactID: contactID)
                }
            case .editContact(let id):
                NavigationStack {
                    AddContactView(contactID: id)
                }
            default:
                EmptyView()
            }
        }
        .onChange(of: presentedSheet) { _, newValue in
            if newValue == nil {
                viewModel.load(id: contactID, context: modelContext)
            }
        }
        .alert(String(localized: "contact.detail.deleteConfirm"), isPresented: $viewModel.isShowingDeleteAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.delete"), role: .destructive) {
                if viewModel.deleteContact(context: modelContext) {
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.load(id: contactID, context: modelContext)
        }
    }

    // MARK: - Profile Section

    private func profileSection(_ contact: Contact) -> some View {
        VStack(spacing: 8) {
            AvatarView(imageData: contact.avatar, name: contact.name, size: 80)

            Text(contact.name)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if !contact.category.isEmpty || !contact.relation.isEmpty {
                HStack(spacing: 6) {
                    if !contact.relation.isEmpty {
                        Text(contact.relation)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.primary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    if !contact.category.isEmpty {
                        Text(contact.category)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.bgTag)
                            .clipShape(Capsule())
                    }
                }
            }

            if !contact.location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(DesignSystem.Typography.small)
                    Text(contact.location)
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    // MARK: - Stats Section

    private func statsSection(_ contact: Contact) -> some View {
        LazyVGrid(columns: statColumns, spacing: 8) {
            StatCard(
                title: String(localized: "contact.detail.given"),
                value: viewModel.formatAmount(contact.totalGiven),
                icon: "arrow.up.right",
                valueColor: DesignSystem.Colors.primary
            )

            StatCard(
                title: String(localized: "contact.detail.received"),
                value: viewModel.formatAmount(contact.totalReceived),
                icon: "arrow.down.left",
                valueColor: DesignSystem.Colors.accentGold
            )

            StatCard(
                title: String(localized: "contact.detail.returned"),
                value: viewModel.formatAmount(contact.totalReturned),
                icon: "arrow.uturn.backward"
            )

            StatCard(
                title: String(localized: "contact.detail.netValue"),
                value: viewModel.formatNetValue(contact.netValue),
                icon: "wallet.bifold",
                valueColor: netValueColor(contact.netValue)
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Personal Info Section

    private func personalInfoSection(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "contact.detail.personalInfo"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                if let birthday = contact.birthday {
                    infoRow(
                        icon: "birthday.cake.fill",
                        label: String(localized: "contact.add.birthday"),
                        value: viewModel.formatDate(birthday)
                    )
                    Divider()
                        .background(DesignSystem.Colors.separator)
                        .padding(.leading, 52)
                }

                infoRow(
                    icon: "circle.grid.2x2.fill",
                    label: String(localized: "contact.detail.circle"),
                    value: viewModel.circleText(contact.circle)
                )

                Divider()
                    .background(DesignSystem.Colors.separator)
                    .padding(.leading, 52)

                infoRow(
                    icon: "bell.badge.fill",
                    label: String(localized: "contact.detail.festivalRecipient"),
                    value: contact.isFestivalReminderRecipient
                        ? String(localized: "common.enabled")
                        : String(localized: "common.disabled")
                )

                if !contact.phone.isEmpty {
                    Divider()
                        .background(DesignSystem.Colors.separator)
                        .padding(.leading, 52)

                    infoRow(
                        icon: "phone.fill",
                        label: String(localized: "contact.add.phone"),
                        value: contact.phone
                    )
                }

                if !contact.note.isEmpty {
                    Divider()
                        .background(DesignSystem.Colors.separator)
                        .padding(.leading, 52)

                    infoRow(
                        icon: "note.text",
                        label: String(localized: "contact.add.notes"),
                        value: contact.note
                    )
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
            .padding(.horizontal, 16)
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 24, height: 24)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Records Section

    private func recordsSection(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(String(localized: "contact.detail.records"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Button {
                    presentedSheet = .addRecord(
                        direction: nil,
                        contactID: contact.persistentModelID
                    )
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .font(DesignSystem.Typography.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            let records = viewModel.sortedRecords

            if records.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "contact.detail.noRecords")
                )
                .frame(height: 160)
            } else {
                VStack(spacing: 0) {
                    ForEach(records) { record in
                        NavigationLink(value: AppRoute.recordDetail(record.persistentModelID)) {
                            RecordRow(
                                avatar: contact.avatar,
                                contactName: contact.name,
                                eventName: record.event?.name ?? "",
                                amount: record.amount,
                                direction: record.direction,
                                date: record.date
                            )
                        }
                        .buttonStyle(.plain)

                        if record.id != records.last?.id {
                            Divider()
                                .background(DesignSystem.Colors.separator)
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Helpers

    private func netValueColor(_ value: Double) -> Color {
        value >= 0
            ? DesignSystem.Colors.accentGold
            : DesignSystem.Colors.primary
    }
}

// MARK: - Preview

private func makeContactDetailPreviewContainer() -> (container: ModelContainer, contactID: PersistentIdentifier)? {
    guard let container = try? ModelContainer(for: Contact.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) else { return nil }
    let context = container.mainContext
    let contact = Contact(
        name: "张三",
        phone: "138-0000-0000",
        relation: "同事",
        category: "社会",
        circle: 4,
        birthday: Date(timeIntervalSince1970: 643_334_400),
        location: "四川 · 成都"
    )
    context.insert(contact)
    return (container, contact.persistentModelID)
}

#Preview {
    Group {
        if let preview = makeContactDetailPreviewContainer() {
            NavigationStack {
                ContactDetailView(contactID: preview.contactID)
            }
            .modelContainer(preview.container)
        } else {
            Text("Preview unavailable")
        }
    }
}
