import SwiftData
import SwiftUI

struct RecordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let recordID: PersistentIdentifier

    @State private var viewModel = RecordDetailViewModel()
    @State private var sheetRoute: SheetRoute?
    @State private var fullScreenPhotoItem: PhotoViewItem?

    var body: some View {
        Group {
            if let record = viewModel.record {
                RecordDetailContentView(
                    record: record,
                    directionLabel: viewModel.directionLabel,
                    paymentMethodName: viewModel.paymentMethodName,
                    contactRecordCount: viewModel.contactRecordCount,
                    contactNetAmount: viewModel.contactNetAmount,
                    formattedDate: viewModel.formattedDate,
                    shouldShowReturnButton: viewModel.shouldShowReturnButton,
                    onReturnTap: showReturnSheet,
                    onPhotoTap: showPhoto(_:)
                )
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
                toolbarMenu
            }
        }
        .onAppear(perform: loadRecord)
        .alert(String(localized: "record.detail.deleteConfirm"), isPresented: $viewModel.isShowingDeleteAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.delete"), role: .destructive, action: deleteRecord)
        }
        .sheet(isPresented: $viewModel.isShowingReturnSheet) {
            RecordDetailReturnSheet(
                record: viewModel.record,
                returnedAmountText: $viewModel.returnedAmountText,
                onSave: saveReturn,
                onCancel: closeReturnSheet
            )
        }
        .sheet(item: $sheetRoute, onDismiss: loadRecord) { route in
            if case let .editRecord(rID) = route {
                NavigationStack {
                    AddRecordView(recordID: rID)
                }
            }
        }
        .fullScreenCover(item: $fullScreenPhotoItem) { item in
            FullScreenPhotoView(imageData: item.data, onDismiss: closePhotoViewer)
        }
    }

    private var toolbarMenu: some View {
        Menu {
            Button(action: editRecord) {
                Label(String(localized: "common.edit"), systemImage: "pencil")
            }
            Button(role: .destructive, action: confirmDelete) {
                Label(String(localized: "common.delete"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "square.and.pencil")
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }

    private func loadRecord() {
        viewModel.load(id: recordID, context: modelContext)
    }

    private func editRecord() {
        sheetRoute = .editRecord(recordID)
    }

    private func confirmDelete() {
        viewModel.isShowingDeleteAlert = true
    }

    private func deleteRecord() {
        if viewModel.deleteRecord(context: modelContext) {
            dismiss()
        }
    }

    private func showReturnSheet() {
        viewModel.isShowingReturnSheet = true
    }

    private func closeReturnSheet() {
        viewModel.returnedAmountText = ""
        viewModel.isShowingReturnSheet = false
    }

    private func saveReturn() {
        if viewModel.saveReturn(context: modelContext) {
            closeReturnSheet()
            loadRecord()
        }
    }

    private func showPhoto(_ imageData: Data) {
        fullScreenPhotoItem = PhotoViewItem(data: imageData)
    }

    private func closePhotoViewer() {
        fullScreenPhotoItem = nil
    }
}

#Preview {
    RecordDetailPreview()
        .modelContainer(for: [Contact.self, Record.self, Event.self, RecordPhoto.self], inMemory: true)
}
