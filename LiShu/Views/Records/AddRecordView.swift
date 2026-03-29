import SwiftUI
import SwiftData
import PhotosUI

struct AddRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddRecordViewModel()
    @State private var showProSheet = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    var direction: RecordDirection?
    var contactID: PersistentIdentifier?
    var recordID: PersistentIdentifier?

    init(direction: RecordDirection? = nil, contactID: PersistentIdentifier? = nil, recordID: PersistentIdentifier? = nil) {
        self.direction = direction
        self.contactID = contactID
        self.recordID = recordID
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                directionToggle
                contactSection
                eventSection
                amountSection
                paymentMethodSection
                dateSection
                photosSection
                notesSection
                confirmButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(viewModel.editingRecord != nil ? String(localized: "record.edit.title") : viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
                .accessibilityIdentifier("record.add.closeButton")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "common.save")) {
                    saveRecord()
                }
                .foregroundStyle(viewModel.isValid ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                .disabled(!viewModel.isValid)
                .accessibilityIdentifier("record.add.saveButton")
            }
        }
        .onAppear {
            viewModel.loadData(context: modelContext)
            if let recordID, let record = modelContext.model(for: recordID) as? Record {
                viewModel.configure(with: record)
            } else {
                viewModel.configure(direction: direction, contactID: contactID, context: modelContext)
            }
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                var loaded: [Data] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty {
                        loaded.append(data)
                    }
                }
                await MainActor.run {
                    viewModel.newPhotoData = loaded
                }
            }
        }
        .sheet(isPresented: $showProSheet) {
            NavigationStack {
                ProMembershipView()
                    .environment(SubscriptionManager.shared)
            }
        }
    }

    // MARK: - Direction Toggle

    private var directionToggle: some View {
        CapsuleSegmentedControl(
            options: [RecordDirection.given, RecordDirection.received],
            selected: $viewModel.direction,
            titleForOption: { option in
                switch option {
                case .given: return String(localized: "record.direction.given")
                case .received: return String(localized: "record.direction.received")
                }
            }
        )
        .padding(.horizontal, 40)
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        InlinePickerField(
            title: viewModel.directionLabel,
            placeholder: String(localized: "record.add.selectContact"),
            placeholderIcon: "person.crop.circle.badge.plus",
            searchPlaceholder: String(localized: "record.add.searchContact"),
            emptyText: String(localized: "record.add.noContact"),
            newButtonTitle: String(localized: "record.add.newContact"),
            selectedItem: $viewModel.selectedContact,
            isShowingPicker: $viewModel.isShowingContactPicker,
            searchText: $viewModel.contactSearchText,
            isCreatingNew: $viewModel.isCreatingNewContact,
            items: viewModel.allContacts,
            filteredItems: viewModel.filteredContacts,
            itemName: { $0.name },
            itemIcon: { contact in
                AnyView(AvatarView(imageData: contact.avatar, name: contact.name, size: 36))
            },
            onToggleCreate: {
                viewModel.isCreatingNewContact.toggle()
                if viewModel.isCreatingNewContact {
                    viewModel.selectedContact = nil
                    viewModel.isShowingContactPicker = false
                    viewModel.contactSearchText = ""
                } else {
                    viewModel.newContactName = ""
                }
            },
            createContent: {
                TextField(String(localized: "record.add.newContactName"), text: $viewModel.newContactName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        )
    }

    // MARK: - Event Section

    private var eventSection: some View {
        InlinePickerField(
            title: String(localized: "record.add.eventType"),
            placeholder: String(localized: "record.add.selectEvent"),
            placeholderIcon: "calendar.badge.plus",
            searchPlaceholder: String(localized: "record.add.searchEvent"),
            emptyText: String(localized: "record.add.noEvent"),
            newButtonTitle: String(localized: "record.add.newEvent"),
            selectedItem: $viewModel.selectedEvent,
            isShowingPicker: $viewModel.isShowingEventPicker,
            searchText: $viewModel.eventSearchText,
            isCreatingNew: $viewModel.isCreatingNewEvent,
            items: viewModel.allEvents,
            filteredItems: viewModel.filteredEvents,
            itemName: { $0.name },
            itemIcon: { event in
                AnyView(
                    Image(systemName: event.type.iconName)
                        .font(.system(size: 18))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(width: 36, height: 36)
                )
            },
            onToggleCreate: {
                viewModel.isCreatingNewEvent.toggle()
                if viewModel.isCreatingNewEvent {
                    viewModel.selectedEvent = nil
                    viewModel.isShowingEventPicker = false
                    viewModel.eventSearchText = ""
                } else {
                    viewModel.newEventName = ""
                    viewModel.newEventType = .other
                }
            },
            createContent: {
                TextField(String(localized: "record.add.newEventName"), text: $viewModel.newEventName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            },
            createExtraContent: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "record.add.selectEventType"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    EventTypePicker(selected: $viewModel.newEventType)
                }
            }
        )
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.amount"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                Text("¥")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                TextField("0", text: $viewModel.amountText)
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("record.add.amountField")
            }
            .frame(minHeight: 36)
            .padding(12)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Payment Method Section

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "record.add.paymentMethod"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(alignment: .center,spacing: 18) {
                Spacer()
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    paymentMethodCapsule(method)
                }
                Spacer()
            }
            .padding(12)
        }
    }

    private func paymentMethodCapsule(_ method: PaymentMethod) -> some View {
        Button {
            viewModel.paymentMethod = method
        } label: {
            HStack(spacing: 4) {
                Image(systemName: paymentMethodIcon(method))
                    .font(.system(size: 12))
                Text(paymentMethodName(method))
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundStyle(
                viewModel.paymentMethod == method
                    ? DesignSystem.Colors.textOnPrimary
                    : DesignSystem.Colors.textSecondary
            )
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                viewModel.paymentMethod == method
                    ? DesignSystem.Colors.primary
                    : DesignSystem.Colors.bgCard
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        viewModel.paymentMethod == method
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.border,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.date"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            HStack {
                DatePicker(
                    "",
                    selection: $viewModel.date,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(DesignSystem.Colors.primary)

                Spacer()
            }
            .padding(12)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.photos"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    existingPhotoThumbnails
                    newPhotoThumbnails
                    addPhotoButton
                }
                .padding(12)
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    @ViewBuilder
    private var existingPhotoThumbnails: some View {
        if let record = viewModel.editingRecord {
            ForEach((record.photos ?? []).sorted(by: { $0.createdAt < $1.createdAt })) { photo in
                photoThumbnail(imageData: photo.imageData)
            }
        }
    }

    private var newPhotoThumbnails: some View {
        ForEach(Array(viewModel.newPhotoData.enumerated()), id: \.offset) { _, data in
            photoThumbnail(imageData: data)
        }
    }

    private func photoThumbnail(imageData: Data) -> some View {
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

    private var addPhotoButton: some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: 20,
            matching: .images
        ) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                Text(String(localized: "record.add.addPhoto"))
                    .font(DesignSystem.Typography.small)
            }
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .frame(width: 80, height: 80)
            .background(DesignSystem.Colors.bgTag)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.notes"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            TextEditor(text: $viewModel.note)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .frame(minHeight: 80)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            saveRecord()
        } label: {
            Text(viewModel.confirmButtonTitle)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!viewModel.isValid)
        .opacity(viewModel.isValid ? 1.0 : 0.6)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func saveRecord() {
        if viewModel.editingRecord == nil, !SubscriptionManager.shared.canAddRecord(context: modelContext) {
            showProSheet = true
            return
        }
        if viewModel.save(context: modelContext) {
            dismiss()
        }
    }

    private func paymentMethodName(_ method: PaymentMethod) -> String {
        switch method {
        case .cash: return String(localized: "payment.cash")
        case .wechat: return String(localized: "payment.wechat")
        case .alipay: return String(localized: "payment.alipay")
        }
    }

    private func paymentMethodIcon(_ method: PaymentMethod) -> String {
        switch method {
        case .cash: return "banknote"
        case .wechat: return "message.fill"
        case .alipay: return "creditcard.fill"
        }
    }

}

#Preview {
    NavigationStack {
        AddRecordView()
    }
    .modelContainer(for: [Contact.self, Record.self, Event.self, RecordPhoto.self], inMemory: true)
}
