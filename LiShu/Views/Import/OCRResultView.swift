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
            .sheet(isPresented: $viewModel.isShowingImportConfig) {
                importConfigSheet
            }
            .sheet(item: $viewModel.editingItem) { _ in
                OCRCorrectionSheet(viewModel: viewModel)
            }
            .onChange(of: viewModel.isShowingImportConfig) { _, newValue in
                InteractionLogger.sheetPresentation(screen: "import.ocr.result", route: "sheet.import.ocrConfig", isPresented: newValue)
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
        .background(DesignSystem.Colors.bgCard)
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

            HStack(spacing: 6) {
                Text(item.eventName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                confidenceLabel(item)
            }
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
                InteractionLogger.tap(
                    screen: "import.ocr.result",
                    target: "import.ocr.result.openImportConfig",
                    route: "sheet.import.ocrConfig",
                    presentation: .sheet
                )
                viewModel.isShowingImportConfig = true
            } label: {
                Text(String(localized: "ocr.import.confirm"))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .padding(.vertical, 10)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.selectedCount == 0)
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

    // MARK: - Import Config Sheet

    private var importConfigSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "ocr.import.direction"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    HStack(spacing: 12) {
                        directionButton(.received, title: String(localized: "record.direction.received"))
                        directionButton(.given, title: String(localized: "record.direction.given"))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "ocr.import.summary"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    let total = viewModel.selectedItems.reduce(0.0) { $0 + $1.amount }
                    Text(
                        String(
                            format: String(localized: "ocr.import.summaryDetail %lld %@"),
                            Int64(viewModel.selectedCount),
                            formatAmount(total)
                        )
                    )
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                }

                Spacer()

                Button {
                    InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.config.confirm")
                    if viewModel.performImport(context: modelContext) {
                        InteractionLogger.submit(
                            screen: "import.ocr.result",
                            target: "import.ocr.config.confirm",
                            action: .save,
                            result: "success",
                            metadata: ["count": String(viewModel.selectedCount)]
                        )
                        viewModel.isShowingImportConfig = false
                    } else {
                        InteractionLogger.submit(
                            screen: "import.ocr.result",
                            target: "import.ocr.config.confirm",
                            action: .save,
                            result: "failed",
                            reason: "import_error"
                        )
                    }
                } label: {
                    if viewModel.isImporting {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text(String(localized: "ocr.import.confirmImport"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.canImport || viewModel.isImporting)
            }
            .padding(20)
            .background(DesignSystem.Colors.bgPage)
            .navigationTitle(String(localized: "ocr.import.configTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.cancel")) {
                        InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.config.cancel")
                        viewModel.isShowingImportConfig = false
                    }
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func directionButton(_ direction: RecordDirection, title: String) -> some View {
        let isSelected = viewModel.direction == direction
        return Button {
            viewModel.direction = direction
            InteractionLogger.tap(screen: "import.ocr.result", target: "import.ocr.config.direction.\(direction.rawValue)")
        } label: {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.bgInput)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(isSelected ? Color.clear : DesignSystem.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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
    OCRResultView(viewModel: {
        let vm = OCRImportViewModel()
        vm.items = [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high, eventName: "婚礼"),
            OCRRecordItem(
                name: "李四",
                amount: 200,
                amountText: "200",
                confidence: .medium,
                warningType: .needsVerification,
                eventName: "婚礼"
            ),
            OCRRecordItem(name: "王五", amount: 1000, amountText: "1,000", confidence: .high, eventName: "生日"),
            OCRRecordItem(name: "赵六", amount: 300, amountText: "300", confidence: .high),
            OCRRecordItem(name: "陈七", amount: 5020, amountText: "5,0?0", confidence: .medium, warningType: .suspiciousAmount),
            OCRRecordItem(name: "周八", amount: 88, amountText: "88", confidence: .high, eventName: "乔迁"),
            OCRRecordItem(name: "吴九", amount: 1200, amountText: "1,200", confidence: .high),
        ]
        vm.processingState = .loaded(vm.items)
        return vm
    }())
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}

#Preview("AI Enhanced") {
    OCRResultView(viewModel: {
        let vm = OCRImportViewModel()
        vm.items = [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high, eventName: "张三婚礼"),
            OCRRecordItem(name: "李四", amount: 200, amountText: "200", confidence: .high, eventName: "李四婚礼"),
            OCRRecordItem(name: "王五", amount: 1000, amountText: "1,000", confidence: .high, eventName: "王五生日宴"),
        ]
        vm.isAIEnhanced = true
        vm.processingState = .loaded(vm.items)
        return vm
    }())
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
