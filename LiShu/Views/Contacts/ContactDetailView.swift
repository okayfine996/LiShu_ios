import SwiftData
import SwiftUI

struct ContactDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let contactID: PersistentIdentifier

    @State private var viewModel = ContactDetailViewModel()
    @State private var presentedSheet: SheetRoute?
    @State private var currentCardPage = 0
    @State private var calendarBirthdaySyncSuccess = false
    @State private var calendarBirthdayError: String?
    @State private var calendarPermissionDenied = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            if let contact = viewModel.contact {
                ScrollView(showsIndicators: false) {
                    ContactDetailContentView(
                        contact: contact,
                        viewModel: viewModel,
                        currentCardPage: $currentCardPage,
                        onAddRecord: { openAddRecord(for: contact) },
                        onAddBirthdayToCalendar: syncBirthdayToCalendar
                    )
                    .padding(.bottom, 24)
                }
            } else if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "contact.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(item: $presentedSheet, content: sheetContent)
        .onChange(of: presentedSheet, handlePresentedSheetChange)
        .alert(
            String(localized: "contact.detail.deleteConfirm"),
            isPresented: $viewModel.isShowingDeleteAlert
        ) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.delete"), role: .destructive, action: deleteContact)
        }
        .alert(String(localized: "contact.detail.calendar.birthdaySuccessTitle"), isPresented: $calendarBirthdaySyncSuccess) {
            Button(String(localized: "common.ok")) {}
        } message: {
            Text(String(localized: "contact.detail.calendar.birthdaySuccessMessage"))
        }
        .alert(String(localized: "calendar.accessDenied.title"), isPresented: $calendarPermissionDenied) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.openSettings")) {
                if let url = URL(string: "app-settings:") { openURL(url) }
            }
        } message: {
            Text(String(localized: "calendar.accessDenied.message"))
        }
        .alert(String(localized: "common.error"), isPresented: calendarBirthdayErrorBinding) {
            Button(String(localized: "common.ok"), action: clearCalendarBirthdayError)
        } message: {
            if let calendarBirthdayError {
                Text(calendarBirthdayError)
            }
        }
        .onAppear(perform: loadContact)
    }
}

private extension ContactDetailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(action: editContact) {
                    Label(String(localized: "common.edit"), systemImage: "pencil")
                }
                Button(role: .destructive, action: showDeleteAlert) {
                    Label(String(localized: "common.delete"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }
    }

    var calendarBirthdayErrorBinding: Binding<Bool> {
        Binding(
            get: { calendarBirthdayError != nil },
            set: { if !$0 { calendarBirthdayError = nil } }
        )
    }

    func syncBirthdayToCalendar() {
        guard let contact = viewModel.contact else { return }
        Task { @MainActor in
            let granted = await CalendarSyncManager.shared.requestWriteAccess()
            guard granted else {
                calendarPermissionDenied = true
                return
            }
            do {
                try CalendarSyncManager.shared.addBirthday(contact: contact)
                calendarBirthdaySyncSuccess = true
            } catch {
                calendarBirthdayError = error.localizedDescription
            }
        }
    }

    func clearCalendarBirthdayError() {
        calendarBirthdayError = nil
    }

    func loadContact() {
        viewModel.load(id: contactID, context: modelContext)
    }

    func handlePresentedSheetChange(_: SheetRoute?, _ newValue: SheetRoute?) {
        if newValue == nil {
            loadContact()
        }
    }

    func openAddRecord(for contact: Contact) {
        presentedSheet = .addRecord(
            direction: nil,
            contactID: contact.persistentModelID,
            eventID: nil
        )
    }

    func editContact() {
        presentedSheet = .editContact(contactID)
    }

    func showDeleteAlert() {
        viewModel.isShowingDeleteAlert = true
    }

    func deleteContact() {
        if viewModel.deleteContact(context: modelContext) {
            dismiss()
        }
    }

    @ViewBuilder
    func sheetContent(for route: SheetRoute) -> some View {
        switch route {
        case let .addRecord(direction, contactID, eventID):
            NavigationStack {
                AddRecordView(direction: direction, contactID: contactID, eventID: eventID)
            }
        case let .editContact(id):
            NavigationStack {
                AddContactView(contactID: id)
            }
        default:
            EmptyView()
        }
    }
}

#Preview {
    Group {
        if let preview = makeContactDetailPreviewContainer() {
            NavigationStack {
                ContactDetailView(contactID: preview.contactID)
            }
            .modelContainer(preview.container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
