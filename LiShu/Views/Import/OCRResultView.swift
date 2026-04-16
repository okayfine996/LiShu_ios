import SwiftData
import SwiftUI

struct OCRResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: OCRImportViewModel

    @State private var pendingDeleteCount = 0
    @State private var showDeleteConfirm = false

    var body: some View {
        OCRResultContentView(
            viewModel: viewModel,
            pendingDeleteCount: pendingDeleteCount,
            showDeleteConfirm: $showDeleteConfirm,
            onRetake: retake,
            onToggleSelectAll: toggleSelectAll,
            onEditItem: editItem(_:),
            onToggleSelection: toggleSelection(for:),
            onDeleteTap: prepareDelete,
            onImportTap: performImport
        )
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("import.ocr.result")
        .navigationBarBackButtonHidden(true)
        .sheet(item: $viewModel.editingItem) { _ in
            OCRCorrectionSheet(viewModel: viewModel)
        }
        .onChange(of: viewModel.editingItem?.id) { _, newValue in
            InteractionLogger.sheetPresentation(
                screen: "import.ocr.result",
                route: "sheet.import.ocrCorrection",
                isPresented: newValue != nil
            )
        }
        .alert(String(localized: "ocr.import.successTitle"), isPresented: $viewModel.importSuccess) {
            Button(String(localized: "common.ok"), action: dismissAfterSuccess)
        } message: {
            Text(successMessageText)
        }
        .alert(String(localized: "common.error"), isPresented: importErrorBinding) {
            Button(String(localized: "common.ok"), action: dismissImportError)
        } message: {
            if let error = viewModel.importError {
                Text(error)
            }
        }
        .alert(String(localized: "ocr.delete.confirmTitle"), isPresented: $showDeleteConfirm) {
            Button(String(localized: "common.cancel"), role: .cancel, action: cancelDelete)
                .accessibilityIdentifier("ocr.delete.cancelButton")

            Button(String(localized: "common.delete"), role: .destructive, action: confirmDeleteSelected)
                .accessibilityIdentifier("ocr.delete.confirmButton")
        } message: {
            Text(String(format: String(localized: "ocr.delete.confirmMessage %lld"), Int64(pendingDeleteCount)))
        }
    }

    private var navigationTitleText: String {
        String(format: String(localized: "ocr.result.title %lld"), Int64(viewModel.items.count))
    }

    private var successMessageText: String {
        String(
            format: String(localized: "ocr.import.successMessage %lld"),
            Int64(viewModel.selectedCount)
        )
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.importError != nil },
            set: { if !$0 { viewModel.importError = nil } }
        )
    }

    private func retake() {
        InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.result.retake")
        viewModel.clearImages()
    }

    private func toggleSelectAll() {
        viewModel.toggleSelectAll()
        InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.result.selectAll")
    }

    private func editItem(_ item: OCRRecordItem) {
        InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.result.editRow")
        viewModel.startEditing(item: item)
    }

    private func toggleSelection(for item: OCRRecordItem) {
        InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.result.toggleSelection")
        viewModel.toggleSelection(for: item)
    }

    private func prepareDelete() {
        pendingDeleteCount = viewModel.selectedCount
        showDeleteConfirm = true
    }

    private func cancelDelete() {
        showDeleteConfirm = false
        pendingDeleteCount = 0
    }

    private func confirmDeleteSelected() {
        guard pendingDeleteCount > 0 else { return }
        InteractionLogger.submit(
            screen: "import.ocr.result",
            target: "import.ocr.result.deleteSelected",
            action: .delete,
            result: "submitted",
            metadata: ["count": String(pendingDeleteCount)]
        )
        viewModel.deleteSelected()
        cancelDelete()
    }

    private func performImport() {
        InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.result.confirmImport")
        if viewModel.performImport(context: modelContext) {
            InteractionLogger.submit(
                screen: "import.ocr.result",
                target: "import.ocr.result.confirmImport",
                action: .save,
                result: "success",
                metadata: ["count": String(viewModel.selectedCount)]
            )
        } else {
            InteractionLogger.submit(
                screen: "import.ocr.result",
                target: "import.ocr.result.confirmImport",
                action: .save,
                result: "failed",
                reason: "import_error"
            )
        }
    }

    private func dismissAfterSuccess() {
        InteractionLogger.alertAction(
            screen: "import.ocr.result",
            target: "import.ocr.success",
            action: .submit,
            result: "dismiss"
        )
        dismiss()
    }

    private func dismissImportError() {
        InteractionLogger.alertAction(
            screen: "import.ocr.result",
            target: "import.ocr.error",
            action: .submit,
            result: "dismiss"
        )
        viewModel.importError = nil
    }
}

#Preview {
    OCRResultPreview()
}

#Preview("AI Enhanced") {
    OCRResultAIEnhancedPreview()
}
