import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct EventDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    let eventID: PersistentIdentifier

    @State var viewModel = EventDetailViewModel()
    @State var pendingDeleteRecord: Record?
    @State var sheetRoute: SheetRoute?
    @State var isShowingGiftReceivingMode = false
    @State var smartReturnGiftResult: SmartReturnGiftResult?
    @State var ledgerImportPreviewViewModel: LedgerImportPreviewViewModel?
    @State var ledgerExportPreviewViewModel: LedgerExportPreviewViewModel?
    @State var showLedgerXLSXImporter = false
    @State var showLedgerImportPreview = false
    @State var showLedgerExportPreview = false
    @State var ledgerShareURL: URL?
    @State var ledgerXLSXError: String?
    @State var isPreparingLedgerXLSX = false
    @State var showLegacyAnomalyList = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage.ignoresSafeArea()

            Group {
                if let event = viewModel.event {
                    EventDetailContentView(
                        event: event,
                        viewModel: viewModel,
                        pendingDeleteRecord: $pendingDeleteRecord,
                        onAddRecord: { openAddRecord(for: event) },
                        onAddLedgerReceipt: { openAddLedgerReceipt(for: event) },
                        onShowLegacyAnomalies: { showLegacyAnomalyList = true },
                        onOpenGiftReceivingMode: { isShowingGiftReceivingMode = true },
                        onSmartReturnGift: smartReturnGiftCallback(for: event),
                        smartReturnGiftBaseline: smartReturnGiftResult?.baselineAmount
                    )
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle(viewModel.event?.name ?? String(localized: "event.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear(perform: loadEvent)
        .onChange(of: sheetRoute, handleSheetRouteChange)
        .onChange(of: showLedgerImportPreview, handleLedgerImportPreviewChange)
        .onChange(of: showLedgerExportPreview, handleLedgerExportPreviewChange)
        .alert(String(localized: "event.detail.deleteConfirm"), isPresented: $viewModel.isShowingDeleteAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.delete"), role: .destructive, action: deleteEvent)
        } message: {
            Text(String(localized: "event.detail.deleteConfirmMessage"))
        }
        .alert(String(localized: "common.error"), isPresented: deleteErrorBinding) {
            Button(String(localized: "common.ok"), action: clearDeleteError)
        } message: {
            if let message = viewModel.deleteError {
                Text(message)
            }
        }
        .alert(
            String(localized: "record.detail.deleteConfirm"),
            isPresented: pendingDeleteRecordBinding
        ) {
            Button(String(localized: "common.cancel"), role: .cancel, action: clearPendingDeleteRecord)
            Button(String(localized: "common.delete"), role: .destructive, action: deletePendingRecord)
        }
        .sheet(item: $sheetRoute, content: sheetContent)
        .sheet(item: ledgerShareURLBinding) { item in
            ShareSheet(url: item.url, onDismiss: clearShareFile)
        }
        .navigationDestination(isPresented: $showLedgerImportPreview) {
            if let ledgerImportPreviewViewModel {
                LedgerImportPreviewView(viewModel: ledgerImportPreviewViewModel) { result in
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
                LedgerExportPreviewView(viewModel: ledgerExportPreviewViewModel) { fileURL in
                    handleConfirmedLedgerExport(fileURL: fileURL)
                }
            }
        }
        .alert(String(localized: "common.error"), isPresented: ledgerXLSXErrorBinding) {
            Button(String(localized: "common.ok"), action: clearLedgerXLSXError)
        } message: {
            if let ledgerXLSXError {
                Text(ledgerXLSXError)
            }
        }
        .overlay {
            if isPreparingLedgerXLSX {
                EventDetailLoadingOverlay()
            }
        }
        .fileImporter(
            isPresented: $showLedgerXLSXImporter,
            allowedContentTypes: [.xlsx],
            allowsMultipleSelection: false,
            onCompletion: handleLedgerXLSXImport
        )
        .fullScreenCover(isPresented: $isShowingGiftReceivingMode, onDismiss: loadEvent) {
            GiftReceivingModeView(eventID: eventID)
        }
    }
}
