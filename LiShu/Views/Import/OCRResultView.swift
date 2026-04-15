import SwiftData
import SwiftUI

struct OCRResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: OCRImportViewModel
    @State private var pendingDeleteCount = 0
    @State private var showDeleteConfirm = false

    var body: some View {
        content
            .background(DesignSystem.Colors.bgPage)
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("import.ocr.result")
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbarContent }
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
                Button(String(localized: "common.ok")) {
                    InteractionLogger.alertAction(
                        screen: "import.ocr.result",
                        target: "import.ocr.success",
                        action: .submit,
                        result: "dismiss"
                    )
                    dismiss()
                }
            } message: {
                Text(successMessageText)
            }
            .alert(String(localized: "common.error"), isPresented: importErrorBinding) {
                Button(String(localized: "common.ok")) {
                    InteractionLogger.alertAction(
                        screen: "import.ocr.result",
                        target: "import.ocr.error",
                        action: .submit,
                        result: "dismiss"
                    )
                    viewModel.importError = nil
                }
            } message: {
                if let error = viewModel.importError {
                    Text(error)
                }
            }
            .alert(String(localized: "ocr.delete.confirmTitle"), isPresented: $showDeleteConfirm) {
                Button(String(localized: "common.cancel"), role: .cancel) {
                    showDeleteConfirm = false
                    pendingDeleteCount = 0
                }
                .accessibilityIdentifier("ocr.delete.cancelButton")

                Button(String(localized: "common.delete"), role: .destructive) {
                    confirmDeleteSelected()
                }
                .accessibilityIdentifier("ocr.delete.confirmButton")
            } message: {
                Text(String(format: String(localized: "ocr.delete.confirmMessage %lld"), Int64(pendingDeleteCount)))
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            if viewModel.lowConfidenceCount > 0 {
                warningBanner
            }

            if viewModel.isAIEnhanced {
                aiEnhancedBadge
            }

            if viewModel.items.isEmpty {
                emptyView
            } else {
                resultList
            }

            bottomToolbar
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            retakeButton
        }
        ToolbarItem(placement: .topBarTrailing) {
            selectAllButton
        }
    }

    private var retakeButton: some View {
        Button {
            InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.result.retake")
            viewModel.clearImages()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text(String(localized: "ocr.result.retake"))
                    .font(DesignSystem.Typography.body)
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }

    private var selectAllButton: some View {
        Button {
            viewModel.toggleSelectAll()
            InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.result.selectAll")
        } label: {
            Text(selectAllButtonTitle)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
        }
        .accessibilityIdentifier("ocr.result.selectAllButton")
    }

    private var selectAllButtonTitle: String {
        viewModel.isAllSelected
            ? String(localized: "ocr.result.deselectAll")
            : String(localized: "ocr.result.selectAll")
    }

    // MARK: - Warning Banner

    private var warningBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(DesignSystem.Colors.accentGold)

            Text(
                String(
                    format: String(localized: "ocr.result.warningBanner %lld"),
                    Int64(viewModel.lowConfidenceCount)
                )
            )
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(DesignSystem.Colors.accentGold.opacity(0.12))
    }

    // MARK: - AI Enhanced Badge

    private var aiEnhancedBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "apple.intelligence")
                .font(.system(size: 13))
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(String(localized: "ocr.ai.enhanced"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(DesignSystem.Colors.primary.opacity(0.08))
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            Text(String(localized: "ocr.result.empty"))
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
        }
    }

    // MARK: - Result List

    private var resultList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.items) { item in
                    resultRow(item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 80)
        }
    }

    // MARK: - Result Row

    private func resultRow(_ item: OCRRecordItem) -> some View {
        HStack(spacing: 14) {
            checkboxButton(item)
            nameAndStatus(item)
            Spacer()
            amountAndIcon(item)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .contentShape(Rectangle())
        .onTapGesture {
            InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.result.editRow")
            viewModel.startEditing(item: item)
        }
    }

    private func checkboxButton(_ item: OCRRecordItem) -> some View {
        Button {
            InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.result.toggleSelection")
            viewModel.toggleSelection(for: item)
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(
                        item.isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                        lineWidth: 2
                    )
                    .frame(width: 26, height: 26)

                if item.isSelected {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 26, height: 26)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func nameAndStatus(_ item: OCRRecordItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            confidenceLabel(item)
        }
    }

    @ViewBuilder
    private func confidenceLabel(_ item: OCRRecordItem) -> some View {
        switch item.confidence {
        case .high:
            Text(String(localized: "ocr.result.confidenceHigh"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        case .medium:
            HStack(spacing: 2) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(DesignSystem.Colors.accentGold)
                Text(warningText(item.warningType))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.accentGold)
            }
        case .low:
            HStack(spacing: 2) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(DesignSystem.Colors.accentGold)
                Text(warningText(item.warningType))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.accentGold)
            }
        }
    }

    private func warningText(_ type: WarningType?) -> String {
        switch type {
        case .needsVerification:
            String(localized: "ocr.result.needsVerification")
        case .suspiciousAmount:
            String(localized: "ocr.result.suspiciousAmount")
        case nil:
            String(localized: "ocr.result.needsVerification")
        }
    }

    private func amountAndIcon(_ item: OCRRecordItem) -> some View {
        HStack(spacing: 8) {
            Text(formatAmount(item.amount))
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(amountColor(item))

            confidenceIcon(item)
        }
    }

    private func amountColor(_ item: OCRRecordItem) -> Color {
        switch item.confidence {
        case .high: DesignSystem.Colors.primary
        case .medium: DesignSystem.Colors.accentGold
        case .low: DesignSystem.Colors.textSecondary
        }
    }

    @ViewBuilder
    private func confidenceIcon(_ item: OCRRecordItem) -> some View {
        switch item.confidence {
        case .high:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(DesignSystem.Colors.primary)
        case .medium:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(DesignSystem.Colors.accentGold)
        case .low:
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        if amount == Double(Int(amount)) {
            return "¥\(Int(amount))"
        }
        return "¥\(String(format: "%.2f", amount))"
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 16) {
            Text(
                String(
                    format: String(localized: "ocr.result.selected %lld"),
                    Int64(viewModel.selectedCount)
                )
            )
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Button {
                pendingDeleteCount = viewModel.selectedCount
                showDeleteConfirm = true
            } label: {
                Text(String(localized: "ocr.delete"))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .accessibilityIdentifier("ocr.result.deleteButton")
            .buttonStyle(SecondaryButtonStyle())
            .disabled(viewModel.selectedCount == 0)

            Button {
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
            } label: {
                if viewModel.isImporting {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 10)
                } else {
                    Text(String(localized: "ocr.import.confirmImport"))
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .padding(.vertical, 10)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.selectedCount == 0 || viewModel.isImporting)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(
            DesignSystem.Colors.bgSurface
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
                .ignoresSafeArea(.container, edges: .bottom)
        )
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
        showDeleteConfirm = false
        pendingDeleteCount = 0
    }
}

#Preview {
    Group {
        if let container = makeOCRResultPreviewContainer() {
            let eventID = ocrResultPreviewEventID(from: container)
            OCRResultView(viewModel: {
                let vm = OCRImportViewModel(eventID: eventID)
                vm.items = [
                    OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
                    OCRRecordItem(
                        name: "李四",
                        amount: 200,
                        amountText: "200",
                        confidence: .medium,
                        warningType: .needsVerification
                    ),
                    OCRRecordItem(name: "王五", amount: 1000, amountText: "1,000", confidence: .high),
                    OCRRecordItem(name: "赵六", amount: 300, amountText: "300", confidence: .high),
                    OCRRecordItem(name: "陈七", amount: 5020, amountText: "5,0?0", confidence: .medium, warningType: .suspiciousAmount),
                    OCRRecordItem(name: "周八", amount: 88, amountText: "88", confidence: .high),
                    OCRRecordItem(name: "吴九", amount: 1200, amountText: "1,200", confidence: .high),
                ]
                vm.processingState = .loaded(vm.items)
                return vm
            }())
                .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}

#Preview("AI Enhanced") {
    Group {
        if let container = makeOCRResultPreviewContainer() {
            let eventID = ocrResultPreviewEventID(from: container)
            OCRResultView(viewModel: {
                let vm = OCRImportViewModel(eventID: eventID)
                vm.items = [
                    OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
                    OCRRecordItem(name: "李四", amount: 200, amountText: "200", confidence: .high),
                    OCRRecordItem(name: "王五", amount: 1000, amountText: "1,000", confidence: .high),
                ]
                vm.isAIEnhanced = true
                vm.processingState = .loaded(vm.items)
                return vm
            }())
                .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}

@MainActor
private func makeOCRResultPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let event = Event(name: "我的婚礼礼簿", type: .wedding, hostMode: .host, date: .now)
    container.mainContext.insert(event)
    return container
}

@MainActor
private func ocrResultPreviewEventID(from container: ModelContainer) -> PersistentIdentifier {
    let descriptor = FetchDescriptor<Event>()
    if let event = try? container.mainContext.fetch(descriptor).first {
        return event.persistentModelID
    }
    let fallbackEvent = Event(name: "我的婚礼礼簿", type: .wedding, hostMode: .host, date: .now)
    container.mainContext.insert(fallbackEvent)
    return fallbackEvent.persistentModelID
}
