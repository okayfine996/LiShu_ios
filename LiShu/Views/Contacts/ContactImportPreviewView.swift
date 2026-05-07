import SwiftData
import SwiftUI

struct ContactImportPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ContactImportPreviewViewModel

    let onImportCompleted: (ContactImportResult) -> Void

    @State private var importErrorMessage: String?

    var body: some View {
        CSVSelectionPreviewView(
            config: viewModel.previewConfig,
            items: viewModel.previewItems,
            isAllSelectableSelected: viewModel.isAllSelectableSelected,
            selectableItemsCount: viewModel.selectableItemsCount,
            isProcessing: viewModel.isProcessing,
            isConfirmEnabled: viewModel.canImport,
            onToggleSelection: { id in
                viewModel.toggleSelection(id: id)
            },
            onSelectAll: {
                viewModel.selectAll()
            },
            onDeselectAll: {
                viewModel.deselectAll()
            },
            onConfirm: {
                Task {
                    await handleConfirmImport()
                }
            }
        )
        .trackScreen("import.contact.xlsx.preview")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    guard !viewModel.isProcessing else { return }
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                .disabled(viewModel.isProcessing)
                .accessibilityIdentifier("contact.xlsx.preview.backButton")
            }
        }
        .alert(String(localized: "common.error"), isPresented: importErrorBinding) {
            Button(String(localized: "common.ok")) {
                importErrorMessage = nil
            }
        } message: {
            if let importErrorMessage {
                Text(importErrorMessage)
            }
        }
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )
    }

    @MainActor
    private func handleConfirmImport() async {
        guard viewModel.canImport else { return }

        viewModel.isImporting = true
        defer { viewModel.isImporting = false }

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(150))

        do {
            let result = try await viewModel.performImport(container: modelContext.container)
            onImportCompleted(result)
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ContactImportPreviewView(
            viewModel: ContactImportPreviewViewModel(
                previewResult: ContactPreviewResult(
                    sourceFileName: "contacts.xlsx",
                    items: [
                        ContactPreviewItem(
                            rowNumber: 2,
                            isSelected: true,
                            name: "张三",
                            detailText: "13800138000 · 北京",
                            status: .ready,
                            payload: ContactPayload(name: "张三", phone: "13800138000", location: "北京")
                        ),
                        ContactPreviewItem(
                            rowNumber: 3,
                            isSelected: false,
                            name: "",
                            detailText: "",
                            status: .error("缺少姓名"),
                            payload: nil
                        ),
                    ]
                )
            ),
            onImportCompleted: { _ in }
        )
    }
    .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
