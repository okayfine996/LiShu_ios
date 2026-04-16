import Foundation
import PhotosUI
import SwiftData
import SwiftUI

struct OCRImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: OCRImportViewModel
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showPhotosPicker = false
    @State private var showProSheet = false
    @State private var hasLoadedUITestFixture = false

    init(eventID: PersistentIdentifier, viewModel: OCRImportViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? OCRImportViewModel(eventID: eventID))
    }

    var body: some View {
        NavigationStack {
            OCRImportStateContainer(
                processingState: viewModel.processingState,
                isAIEnhanced: viewModel.isAIEnhanced,
                viewModel: viewModel,
                onOpenCamera: openCamera,
                onOpenAlbum: openAlbum,
                onRetry: retryProcessing
            )
            .background(DesignSystem.Colors.bgPage)
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("import.ocr.source")
            .toolbar {
                if shouldShowCancelButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(String(localized: "common.cancel"), action: cancel)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 20,
            matching: .images
        )
        .onChange(of: selectedPhotos) { _, newItems in
            guard !newItems.isEmpty else { return }
            InteractionLogger.tap(
                screen: "import.ocr.source",
                target: "import.ocr.albumSelection",
                route: "photosPicker"
            )
            loadPhotos(newItems)
        }
        .fullScreenCover(isPresented: $viewModel.isShowingCamera) {
            CameraImagePicker { image in
                viewModel.addImage(image)
                startProcessingIfNeeded()
            }
            .ignoresSafeArea()
        }
        .onChange(of: viewModel.isShowingCamera) { _, newValue in
            InteractionLogger.fullScreenPresentation(
                screen: "import.ocr.source",
                route: "fullScreen.import.camera",
                isPresented: newValue
            )
        }
        .sheet(isPresented: $showProSheet) {
            NavigationStack {
                ProMembershipView()
                    .environment(SubscriptionManager.shared)
            }
        }
        .onChange(of: showProSheet) { _, newValue in
            InteractionLogger.sheetPresentation(
                screen: "import.ocr.source",
                route: "sheet.settings.proMembership",
                isPresented: newValue
            )
        }
        .onAppear(perform: applyUITestFixtureIfNeeded)
    }

    private var shouldShowCancelButton: Bool {
        if case .idle = viewModel.processingState { return true }
        if case .error = viewModel.processingState { return true }
        return false
    }

    private func cancel() {
        let target = switch viewModel.processingState {
        case .error:
            "import.ocr.error.cancel"
        default:
            "import.ocr.cancel"
        }
        InteractionLogger.tap(screen: "import.ocr.source", target: target)
        dismiss()
    }

    private func retryProcessing() {
        InteractionLogger.tap(screen: "import.ocr.source", target: "import.ocr.retry")
        viewModel.clearImages()
    }

    private func openCamera() {
        guard SubscriptionManager.shared.canUseOCR() else {
            InteractionLogger.submit(
                screen: "import.ocr.source",
                target: "import.ocr.camera",
                action: .open,
                result: "blocked",
                reason: "subscription_limit"
            )
            showProSheet = true
            return
        }

        InteractionLogger.tap(
            screen: "import.ocr.source",
            target: "import.ocr.camera",
            route: "fullScreen.import.camera",
            presentation: .fullScreen
        )
        viewModel.isShowingCamera = true
    }

    private func openAlbum() {
        guard SubscriptionManager.shared.canUseOCR() else {
            InteractionLogger.submit(
                screen: "import.ocr.source",
                target: "import.ocr.album",
                action: .open,
                result: "blocked",
                reason: "subscription_limit"
            )
            showProSheet = true
            return
        }

        InteractionLogger.tap(
            screen: "import.ocr.source",
            target: "import.ocr.album",
            route: "photosPicker"
        )
        showPhotosPicker = true
    }

    private func applyUITestFixtureIfNeeded() {
        guard !hasLoadedUITestFixture else { return }
        hasLoadedUITestFixture = true

        guard CommandLine.arguments.contains("--uitesting") else { return }
        guard let event = modelContext.model(for: viewModel.eventID) as? Event, event.hostMode == .host else {
            viewModel.processingState = .error(String(localized: "common.error"))
            return
        }
        guard let fixtureItems = parseUITestFixtureItems(), !fixtureItems.isEmpty else { return }

        viewModel.items = fixtureItems
        viewModel.processingState = .loaded(fixtureItems)
    }

    private func parseUITestFixtureItems() -> [OCRRecordItem]? {
        guard let rawPayload = ProcessInfo.processInfo.environment["UITEST_OCR_PREVIEW_ITEMS"] else {
            return nil
        }
        let records = rawPayload
            .split(separator: ";")
            .compactMap { parseUITestFixtureItem(String($0)) }
        return records.isEmpty ? nil : records
    }

    private func parseUITestFixtureItem(_ itemPayload: String) -> OCRRecordItem? {
        let parts = itemPayload.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count >= 2 else { return nil }

        let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let amount = Double(parts[1]) ?? 0
        let amountText = parts.count > 2 && !parts[2].isEmpty ? String(parts[2]) : "\(amount)"
        let confidence = OCRConfidence(rawValue: String(parts.dropFirst(3).first ?? "high")) ?? .high
        let warningType = parts.dropFirst(4).first.flatMap { WarningType(rawValue: String($0)) }

        return OCRRecordItem(
            name: name,
            amount: amount,
            amountText: amountText,
            confidence: confidence,
            warningType: warningType
        )
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let optimized = ImagePipeline.optimizedJPEGData(
                       from: data,
                       maxPixelSize: ImagePipeline.Preset.ocrInputMaxPixelSize,
                       compressionQuality: 0.82
                   ),
                   let image = UIImage(data: optimized)
                {
                    images.append(image)
                }
            }

            await MainActor.run {
                viewModel.capturedImages = images
                selectedPhotos = []
            }

            if !images.isEmpty {
                guard SubscriptionManager.shared.canUseOCR() else {
                    await MainActor.run { showProSheet = true }
                    return
                }
                await viewModel.processImages()
            }
        }
    }

    private func startProcessingIfNeeded() {
        guard !viewModel.capturedImages.isEmpty else { return }
        guard SubscriptionManager.shared.canUseOCR() else {
            showProSheet = true
            return
        }
        Task {
            await viewModel.processImages()
        }
    }
}

#Preview {
    OCRImportPreview()
}

#Preview("Processing") {
    OCRImportProcessingPreview(processingState: .loading, isAIEnhanced: false)
}

#Preview("AI Processing") {
    OCRImportProcessingPreview(processingState: .loading, isAIEnhanced: true)
}

#Preview("Error") {
    OCRImportProcessingPreview(
        processingState: .error(String(localized: "ocr.error.recognitionFailed")),
        isAIEnhanced: false
    )
}
