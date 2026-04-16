import SwiftData
import SwiftUI

struct ContactDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let contactID: PersistentIdentifier

    @State private var viewModel = ContactDetailViewModel()
    @State private var presentedSheet: SheetRoute?
    @State private var currentCardPage = 0

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
                        onAddRecord: { openAddRecord(for: contact) }
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
