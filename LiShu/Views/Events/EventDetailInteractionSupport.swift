import SwiftData
import SwiftUI

extension EventDetailView {
    var deleteErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )
    }

    var pendingDeleteRecordBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteRecord != nil },
            set: { if !$0 { pendingDeleteRecord = nil } }
        )
    }

    var ledgerCSVErrorBinding: Binding<Bool> {
        Binding(
            get: { ledgerCSVError != nil },
            set: { if !$0 { ledgerCSVError = nil } }
        )
    }

    var ledgerShareURLBinding: Binding<EventDetailShareableFile?> {
        Binding(
            get: { ledgerShareURL.map { EventDetailShareableFile(id: $0.absoluteString, url: $0) } },
            set: {
                if let url = ledgerShareURL, $0 == nil {
                    try? FileManager.default.removeItem(at: url)
                }
                ledgerShareURL = $0?.url
            }
        )
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if viewModel.event?.hostMode == .host {
                    hostLedgerActions
                }
                commonEventActions
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }
    }

    @ViewBuilder
    var hostLedgerActions: some View {
        Button(action: addLedgerReceiptFromToolbar) {
            Label(String(localized: "event.ledger.primaryAction"), systemImage: "plus.circle")
        }
        Button(action: openOCRImport) {
            Label(String(localized: "record.ocr.import"), systemImage: "doc.viewfinder")
        }
        Button(action: openLedgerCSVImporter) {
            Label(String(localized: "event.ledger.importCSV"), systemImage: "square.and.arrow.down")
        }
        Button(action: prepareLedgerExportPreview) {
            Label(String(localized: "event.ledger.exportCSV"), systemImage: "square.and.arrow.up")
        }
        Button(action: downloadLedgerTemplate) {
            Label(String(localized: "event.ledger.downloadTemplate"), systemImage: "arrow.down.doc")
        }
    }

    @ViewBuilder
    var commonEventActions: some View {
        Button(action: editEvent) {
            Label(String(localized: "common.edit"), systemImage: "pencil")
        }
        Button(role: .destructive, action: showDeleteAlert) {
            Label(String(localized: "common.delete"), systemImage: "trash")
        }
    }

    func loadEvent() {
        viewModel.load(id: eventID, context: modelContext)
        if let event = viewModel.event {
            computeSmartReturnGiftResult(for: event)
        }
    }

    func handleSheetRouteChange(_: SheetRoute?, _ newValue: SheetRoute?) {
        if newValue == nil {
            loadEvent()
        }
    }

    func handleLedgerImportPreviewChange(_: Bool, _ newValue: Bool) {
        if !newValue {
            ledgerImportPreviewViewModel = nil
        }
    }

    func handleLedgerExportPreviewChange(_: Bool, _ newValue: Bool) {
        if !newValue {
            ledgerExportPreviewViewModel = nil
        }
    }

    func showDeleteAlert() {
        viewModel.isShowingDeleteAlert = true
    }

    func clearDeleteError() {
        viewModel.deleteError = nil
    }

    func clearPendingDeleteRecord() {
        pendingDeleteRecord = nil
    }

    func clearLedgerCSVError() {
        ledgerCSVError = nil
    }

    func deleteEvent() {
        if viewModel.deleteEvent(context: modelContext) {
            dismiss()
        }
    }

    func deletePendingRecord() {
        guard let pendingDeleteRecord else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            _ = viewModel.deleteRecord(pendingDeleteRecord, context: modelContext)
        }
        self.pendingDeleteRecord = nil
    }

    func openAddRecord(for event: Event) {
        sheetRoute = .addRecord(
            direction: .given,
            contactID: nil,
            eventID: event.persistentModelID
        )
    }

    func openSmartReturnGift(for event: Event) {
        guard let contact = event.primaryContact else { return }
        sheetRoute = .smartReturnGift(
            eventID: event.persistentModelID,
            contactID: contact.persistentModelID
        )
    }

    /// Returns the smart return gift callback only when the event is upcoming, guest-mode, has a primaryContact, and no gift has been given
    /// yet.
    func smartReturnGiftCallback(for event: Event) -> (() -> Void)? {
        guard viewModel.isUpcoming,
              event.hostMode == .guest,
              event.primaryContact != nil,
              !event.hasGivenRecord else { return nil }
        return { openSmartReturnGift(for: event) }
    }

    func computeSmartReturnGiftResult(for event: Event) {
        guard
            viewModel.isUpcoming,
            event.hostMode == .guest,
            !event.hasGivenRecord,
            let contact = event.primaryContact
        else {
            smartReturnGiftResult = nil
            return
        }
        let allRecords = contact.records ?? []
        smartReturnGiftResult = SmartReturnGiftEngine.calculate(
            contact: contact,
            event: event,
            allContactRecords: allRecords
        )
    }

    func openAddLedgerReceipt(for event: Event) {
        sheetRoute = .addLedgerReceipt(eventID: event.persistentModelID)
    }

    func addLedgerReceiptFromToolbar() {
        guard let event = viewModel.event else { return }
        openAddLedgerReceipt(for: event)
    }

    func openOCRImport() {
        sheetRoute = .ocrImport(eventID: eventID)
    }

    func openLedgerCSVImporter() {
        guard !isPreparingLedgerCSV else { return }
        showLedgerCSVImporter = true
    }

    func editEvent() {
        sheetRoute = .editEvent(eventID)
    }

    @ViewBuilder
    func sheetContent(for route: SheetRoute) -> some View {
        switch route {
        case let .addRecord(direction, contactID, eventID):
            NavigationStack {
                AddRecordView(direction: direction, contactID: contactID, eventID: eventID)
            }
        case let .addLedgerReceipt(eventID):
            NavigationStack {
                AddLedgerReceiptView(eventID: eventID)
            }
        case let .editEvent(eventID):
            NavigationStack {
                AddEventView(eventID: eventID)
            }
        case let .ocrImport(eventID):
            OCRImportView(eventID: eventID)
        case let .smartReturnGift(eventID, contactID):
            NavigationStack {
                SmartReturnGiftView(eventID: eventID, contactID: contactID)
            }
        default:
            EmptyView()
        }
    }

    func handleLedgerCSVImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first, let event = viewModel.event else { return }
            guard !isPreparingLedgerCSV else { return }
            isPreparingLedgerCSV = true

            Task {
                do {
                    let preview = try await ExportService.previewLedgerCSVAsync(
                        url: url,
                        eventName: event.name
                    )
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

    func prepareLedgerExportPreview() {
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
    func handleCompletedLedgerImport(_: ImportResult) {
        showLedgerImportPreview = false
        loadEvent()
        ledgerCSVError = nil
    }

    @MainActor
    func handleConfirmedLedgerExport(fileURL: URL) {
        showLedgerExportPreview = false
        ledgerShareURL = fileURL
    }

    func downloadLedgerTemplate() {
        do {
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("lishu_ledger_template.csv")
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

    func clearShareFile() {
        guard let ledgerShareURL else { return }
        self.ledgerShareURL = nil
        try? FileManager.default.removeItem(at: ledgerShareURL)
    }
}

struct EventDetailShareableFile: Identifiable {
    let id: String
    let url: URL
}
