import PhotosUI
import SwiftData
import SwiftUI

struct AddRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddRecordViewModel()
    @State private var showProSheet = false
    @State private var showAddEventSheet = false
    @State private var showAddContactSheet = false
    @State private var contactIDsBeforeAddSheet: Set<PersistentIdentifier> = []
    @State private var eventIDsBeforeCreation: Set<PersistentIdentifier> = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var continuousSaveMessage: String?

    let direction: RecordDirection?
    let contactID: PersistentIdentifier?
    let eventID: PersistentIdentifier?
    let recordID: PersistentIdentifier?

    init(
        direction: RecordDirection? = nil,
        contactID: PersistentIdentifier? = nil,
        eventID: PersistentIdentifier? = nil,
        recordID: PersistentIdentifier? = nil
    ) {
        self.direction = direction
        self.contactID = contactID
        self.eventID = eventID
        self.recordID = recordID
    }

    private var locksContextToInitialEvent: Bool {
        recordID == nil && eventID != nil
    }

    var body: some View {
        AddRecordFormView(
            viewModel: viewModel,
            locksContextToInitialEvent: locksContextToInitialEvent,
            selectedPhotoItems: $selectedPhotoItems,
            continuousSaveMessage: continuousSaveMessage,
            onCreateContact: openAddContact,
            onCreateEvent: openAddEvent,
            onSave: { saveRecord(andContinue: false) }
        )
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear(perform: loadData)
        .onChange(of: selectedPhotoItems) { _, newItems in
            handleSelectedPhotoItems(newItems)
        }
        .sheet(isPresented: $showProSheet, content: makeProSheet)
        .sheet(isPresented: $showAddEventSheet, onDismiss: refreshEventsAfterCreation, content: makeAddEventSheet)
        .sheet(isPresented: $showAddContactSheet, onDismiss: refreshContactsAfterAddSheet, content: makeAddContactSheet)
    }

    private var navigationTitle: String {
        viewModel.editingRecord != nil ? String(localized: "record.edit.title") : viewModel.navigationTitle
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(String(localized: "common.cancel"), action: dismiss.callAsFunction)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .accessibilityIdentifier("record.add.cancelButton")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(String(localized: "common.save"), action: { saveRecord(andContinue: false) })
                .foregroundStyle(viewModel.isValid ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                .disabled(!viewModel.isValid)
                .accessibilityIdentifier("record.add.saveButton")
        }
    }

    private func makeProSheet() -> some View {
        NavigationStack {
            ProMembershipView()
                .environment(SubscriptionManager.shared)
        }
    }

    private func makeAddEventSheet() -> some View {
        NavigationStack {
            AddEventView()
        }
    }

    private func makeAddContactSheet() -> some View {
        NavigationStack {
            AddContactView()
        }
    }

    private func loadData() {
        viewModel.loadData(context: modelContext)
        if let recordID, let record = modelContext.model(for: recordID) as? Record {
            viewModel.configure(with: record)
        } else {
            viewModel.configure(direction: direction, contactID: contactID, eventID: eventID, context: modelContext)
        }
    }

    private func handleSelectedPhotoItems(_ items: [PhotosPickerItem]) {
        Task {
            var loaded: [NewRecordPhotoItem] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty,
                   let optimized = ImagePipeline.optimizedJPEGData(
                       from: data,
                       maxPixelSize: ImagePipeline.Preset.recordPhotoMaxPixelSize,
                       compressionQuality: 0.84
                   )
                {
                    loaded.append(NewRecordPhotoItem(id: UUID(), data: optimized))
                }
            }
            await MainActor.run {
                viewModel.newPhotoItems = loaded
            }
        }
    }

    private func openAddEvent() {
        eventIDsBeforeCreation = Set(viewModel.allEvents.map(\.persistentModelID))
        showAddEventSheet = true
    }

    private func openAddContact() {
        contactIDsBeforeAddSheet = Set(viewModel.allContacts.map(\.persistentModelID))
        showAddContactSheet = true
    }

    private func refreshEventsAfterCreation() {
        viewModel.loadData(context: modelContext)
        let newEvents = viewModel.allEvents.filter { !eventIDsBeforeCreation.contains($0.persistentModelID) }
        if let newestEvent = newEvents.max(by: { $0.createdAt < $1.createdAt }) {
            viewModel.selectEvent(newestEvent)
        }
        eventIDsBeforeCreation = []
    }

    private func refreshContactsAfterAddSheet() {
        viewModel.loadData(context: modelContext)
        let newContacts = viewModel.allContacts.filter { !contactIDsBeforeAddSheet.contains($0.persistentModelID) }
        if let newestContact = newContacts.max(by: { $0.createdAt < $1.createdAt }) {
            viewModel.selectedContact = newestContact
        }
        contactIDsBeforeAddSheet = []
    }

    private func saveRecord(andContinue: Bool) {
        if viewModel.editingRecord == nil, !SubscriptionManager.shared.canAddRecord(context: modelContext) {
            showProSheet = true
            return
        }

        if viewModel.save(context: modelContext) {
            guard andContinue else {
                AdManager.shared.scheduleNativeAd()
                dismiss()
                return
            }

            let contactName = viewModel.selectedContact?.name ?? ""
            let amount = viewModel.recordType == .monetary ? viewModel.monetaryAmount : ""
            if !contactName.isEmpty {
                continuousSaveMessage = String(
                    format: String(localized: "record.add.continueSuccess"),
                    contactName,
                    amount.isEmpty ? "0" : amount
                )
            }
            viewModel.resetForContinuousEntry()
            selectedPhotoItems = []
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                continuousSaveMessage = nil
            }
        }
    }
}

// MARK: - Preview

@MainActor
private func makeAddRecordPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self, RecordPhoto.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext
    let cal = Calendar.current
    let now = Date()

    let c1 = Contact(name: "张三", relation: "同事", category: "社交", circle: 3)
    let c2 = Contact(name: "李四", relation: "朋友", category: "社交", circle: 3)
    let c3 = Contact(name: "王五", relation: "舅舅", category: "亲属", circle: 2)
    let c4 = Contact(name: "赵六", relation: "同学", category: "社交", circle: 3)
    let c5 = Contact(name: "钱七", relation: "邻居", category: "其他", circle: 4)
    let c6 = Contact(name: "孙八", relation: "客户", category: "社交", circle: 3)
    [c1, c2, c3, c4, c5, c6].forEach { ctx.insert($0) }

    let e1 = Event(name: "表哥的婚礼", type: .wedding, date: cal.liShuDateByAddingDays(5, to: now), location: "家乡酒店")
    let e2 = Event(name: "小李30岁生日", type: .birthday, date: cal.liShuDateByAddingDays(12, to: now), location: "上海")
    let e3 = Event(name: "硕士毕业典礼", type: .education, date: cal.liShuDateByAddingDays(20, to: now), location: "广州")
    let e4 = Event(name: "春节拜年", type: .festival, date: cal.liShuDateByAddingMonths(-1, to: now), location: "老家")
    let e5 = Event(name: "王总乔迁", type: .property, date: cal.liShuDateByAddingDays(-5, to: now), location: "深圳")
    let e6 = Event(name: "爷爷丧事", type: .funeral, date: cal.liShuDateByAddingMonths(-2, to: now), location: "县城")
    let e7 = Event(name: "新店开业", type: .business, date: cal.liShuDateByAddingDays(30, to: now), location: "杭州")
    [e1, e2, e3, e4, e5, e6, e7].forEach { ctx.insert($0) }

    let r1 = Record.makeMonetaryRecord(
        contact: c1,
        event: e1,
        amount: 800,
        direction: .given,
        paymentMethod: .wechat,
        date: now
    )
    let r2 = Record.makeMonetaryRecord(
        contact: c2,
        event: e2,
        amount: 600,
        direction: .given,
        paymentMethod: .cash,
        date: cal.liShuDateByAddingDays(-2, to: now)
    )
    let r3 = Record.makeMonetaryRecord(
        contact: c3,
        event: e4,
        amount: 500,
        direction: .received,
        paymentMethod: .alipay,
        date: cal.liShuDateByAddingMonths(-1, to: now)
    )
    let r4 = Record.makeMonetaryRecord(
        contact: c4,
        event: nil,
        amount: 200,
        direction: .given,
        paymentMethod: .wechat,
        date: cal.liShuDateByAddingDays(-3, to: now)
    )
    r4.contextTag = "年会凑份"
    let r5 = Record.makeMonetaryRecord(
        contact: c5,
        event: nil,
        amount: 100,
        direction: .given,
        date: cal.liShuDateByAddingDays(-10, to: now)
    )
    r5.contextTag = "社区互助"
    [r1, r2, r3, r4, r5].forEach { ctx.insert($0) }

    return container
}

#Preview {
    Group {
        if let container = makeAddRecordPreviewContainer() {
            NavigationStack {
                AddRecordView()
            }
            .modelContainer(container)
            .environment(SubscriptionManager.shared)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
