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
            Group {
                switch viewModel.processingState {
                case .idle:
                    sourceSelectionView
                case .loading:
                    processingView
                case .loaded:
                    OCRResultView(viewModel: viewModel)
                case let .error(message):
                    errorView(message)
                }
            }
            .background(DesignSystem.Colors.bgPage)
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("import.ocr.source")
            .toolbar {
                if case .idle = viewModel.processingState {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(String(localized: "common.cancel")) {
                            InteractionLogger.tap(screen: "import.ocr.source", target: "import.ocr.cancel")
                            dismiss()
                        }
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                if case .error = viewModel.processingState {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(String(localized: "common.cancel")) {
                            InteractionLogger.tap(screen: "import.ocr.source", target: "import.ocr.error.cancel")
                            dismiss()
                        }
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
            InteractionLogger.tap(screen: "import.ocr.source", target: "import.ocr.albumSelection", route: "photosPicker")
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
            InteractionLogger.fullScreenPresentation(screen: "import.ocr.source", route: "fullScreen.import.camera", isPresented: newValue)
        }
        .sheet(isPresented: $showProSheet) {
            NavigationStack {
                ProMembershipView()
                    .environment(SubscriptionManager.shared)
            }
        }
        .onChange(of: showProSheet) { _, newValue in
            InteractionLogger.sheetPresentation(screen: "import.ocr.source", route: "sheet.settings.proMembership", isPresented: newValue)
        }
        .onAppear {
            applyUITestFixtureIfNeeded()
        }
    }

    private func applyUITestFixtureIfNeeded() {
        guard !hasLoadedUITestFixture else { return }
        hasLoadedUITestFixture = true

        guard CommandLine.arguments.contains("--uitesting") else { return }
        guard let event = modelContext.model(for: viewModel.eventID) as? Event, event.hostMode == .host else {
            viewModel.processingState = .error(String(localized: "common.error"))
            return
        }
        guard let fixtureItems = parseUITestFixtureItems() else { return }
        guard !fixtureItems.isEmpty else { return }

        viewModel.items = fixtureItems
        viewModel.processingState = .loaded(fixtureItems)
    }

    private func parseUITestFixtureItems() -> [OCRRecordItem]? {
        guard let rawPayload = ProcessInfo.processInfo.environment["UITEST_OCR_PREVIEW_ITEMS"] else { return nil }
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
        let warningType = parts.dropFirst(4).first
            .flatMap { WarningType(rawValue: String($0)) }

        return OCRRecordItem(
            name: name,
            amount: amount,
            amountText: amountText,
            confidence: confidence,
            warningType: warningType
        )
    }

    // MARK: - Source Selection

    private var sourceSelectionView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 56))
                    .foregroundStyle(DesignSystem.Colors.primary)

                VStack(spacing: 8) {
                    Text(String(localized: "ocr.source.title"))
                        .font(DesignSystem.Typography.title2)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(String(localized: "ocr.source.subtitle"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button {
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
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                            Text(String(localized: "ocr.source.camera"))
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
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
                        InteractionLogger.tap(screen: "import.ocr.source", target: "import.ocr.album", route: "photosPicker")
                        showPhotosPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18))
                            Text(String(localized: "ocr.source.album"))
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .navigationTitle(String(localized: "ocr.import.title"))
    }

    // MARK: - Processing

    private var processingView: some View {
        VStack(spacing: 20) {
            Spacer()

            if viewModel.isAIEnhanced {
                AISparkleIcon()
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(DesignSystem.Colors.primary)
            }

            Text(viewModel.isAIEnhanced
                ? String(localized: "ocr.ai.processing")
                : String(localized: "ocr.import.processing"))
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(String(localized: "ocr.import.processingHint"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(String(localized: "ocr.import.title"))
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(String(localized: "ocr.error.title"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(message)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                InteractionLogger.tap(screen: "import.ocr.source", target: "import.ocr.retry")
                viewModel.clearImages()
            } label: {
                Text(String(localized: "ocr.error.retry"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)

            Spacer()
        }
        .navigationTitle(String(localized: "ocr.import.title"))
    }

    // MARK: - Helpers

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
    Group {
        if let container = makeOCRImportPreviewContainer() {
            OCRImportView(eventID: previewLedgerEventID(from: container))
                .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}

#Preview("Processing") {
    OCRImportStatePreviewHost(processingState: .loading, isAIEnhanced: false)
}

#Preview("AI Processing") {
    OCRImportStatePreviewHost(processingState: .loading, isAIEnhanced: true)
}

#Preview("Error") {
    OCRImportStatePreviewHost(
        processingState: .error(String(localized: "ocr.error.recognitionFailed")),
        isAIEnhanced: false
    )
}

@MainActor
private func makeOCRImportPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }

    let event = Event(name: "我的婚礼礼簿", type: .wedding, hostMode: .host, date: .now)
    container.mainContext.insert(event)
    return container
}

@MainActor
private func previewLedgerEventID(from container: ModelContainer) -> PersistentIdentifier {
    let descriptor = FetchDescriptor<Event>()
    if let event = try? container.mainContext.fetch(descriptor).first {
        return event.persistentModelID
    }

    let fallbackEvent = Event(name: "我的婚礼礼簿", type: .wedding, hostMode: .host, date: .now)
    container.mainContext.insert(fallbackEvent)
    return fallbackEvent.persistentModelID
}

@MainActor
private struct OCRImportStatePreviewHost: View {
    private let container: ModelContainer?
    private let eventID: PersistentIdentifier?
    private let viewModel: OCRImportViewModel?

    init(processingState: LoadingState<[OCRRecordItem]>, isAIEnhanced: Bool) {
        if let container = makeOCRImportPreviewContainer() {
            let eventID = previewLedgerEventID(from: container)
            let viewModel = OCRImportViewModel(eventID: eventID)
            viewModel.processingState = processingState
            viewModel.isAIEnhanced = isAIEnhanced

            self.container = container
            self.eventID = eventID
            self.viewModel = viewModel
        } else {
            container = nil
            eventID = nil
            viewModel = nil
        }
    }

    var body: some View {
        if let container, let eventID, let viewModel {
            OCRImportView(eventID: eventID, viewModel: viewModel)
                .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
