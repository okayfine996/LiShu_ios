import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showComingSoonToast = false
    @State private var toastMessage = ""
    @State private var showCSVPreview = false
    @State private var csvPreviewViewModel: CSVImportPreviewViewModel?
    @State private var exportError: String?
    @State private var showCSVImporter = false
    @State private var importResult: String?
    @State private var didLoadUITestCSVPreview = false
    @State private var didRequestUITestCSVImporter = false
    @State private var isPreparingCSVPreview = false

    var body: some View {
        DataManagementContentView(
            onImportCSV: openCSVImporter,
            isPreparingCSVPreview: isPreparingCSVPreview
        )
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "settings.importExport"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showCSVPreview) {
            if let csvPreviewViewModel {
                CSVImportPreviewView(viewModel: csvPreviewViewModel) { result in
                    handleCompletedCSVImport(result)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showComingSoonToast {
                toastView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 32)
            }
        }
        .overlay(alignment: .topLeading) {
            if CommandLine.arguments.contains("--uitesting"), didRequestUITestCSVImporter {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityElement()
                    .accessibilityIdentifier("csv.importer.requested")
            }
        }
        .alert(String(localized: "common.error"), isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button(String(localized: "common.ok")) { exportError = nil }
        } message: {
            if let msg = exportError { Text(msg) }
        }
        .overlay {
            if isPreparingCSVPreview {
                csvImportLoadingOverlay
            }
        }
        .fileImporter(
            isPresented: $showCSVImporter,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleCSVImport(result)
        }
        .onChange(of: showCSVPreview) { _, newValue in
            if !newValue {
                csvPreviewViewModel = nil
            }
        }
        .onAppear {
            loadUITestCSVPreviewIfNeeded()
        }
    }

    private func showToast() {
        toastMessage = String(localized: "settings.data.comingSoon")
        withAnimation(.easeInOut(duration: 0.3)) {
            showComingSoonToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showComingSoonToast = false
            }
        }
    }

    private func openCSVImporter() {
        guard !isPreparingCSVPreview else { return }
        if CommandLine.arguments.contains("--uitesting") {
            didRequestUITestCSVImporter = true
            if ProcessInfo.processInfo.environment["UITEST_SKIP_SYSTEM_CSV_IMPORTER"] == "1" {
                return
            }
        }
        showCSVImporter = true
    }

    private func handleCSVImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            guard !isPreparingCSVPreview else { return }
            isPreparingCSVPreview = true

            Task {
                do {
                    let preview = try await ExportService.previewCSVAsync(url: url)
                    csvPreviewViewModel = CSVImportPreviewViewModel(previewResult: preview)
                    showCSVPreview = true
                } catch {
                    exportError = error.localizedDescription
                }

                isPreparingCSVPreview = false
            }
        case let .failure(error):
            exportError = error.localizedDescription
        }
    }

    private func handleCompletedCSVImport(_ result: ImportResult) {
        showCSVPreview = false
        importResult = String(
            format: String(localized: "settings.data.importResult %lld %lld %lld"),
            Int64(result.imported),
            Int64(result.skipped),
            Int64(result.errors)
        )
        toastMessage = importResult ?? ""
        withAnimation(.easeInOut(duration: 0.3)) {
            showComingSoonToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showComingSoonToast = false
            }
        }
    }

    private func loadUITestCSVPreviewIfNeeded() {
        guard !didLoadUITestCSVPreview else { return }
        didLoadUITestCSVPreview = true

        guard CommandLine.arguments.contains("--uitesting") else { return }
        guard let content = ProcessInfo.processInfo.environment["UITEST_CSV_PREVIEW_CONTENT"], !content.isEmpty else { return }

        let fileName = ProcessInfo.processInfo.environment["UITEST_CSV_PREVIEW_FILENAME"] ?? "ui-test-preview.csv"
        isPreparingCSVPreview = true

        Task {
            do {
                let preview = try await ExportService.previewCSVAsync(content: content, sourceFileName: fileName)
                csvPreviewViewModel = CSVImportPreviewViewModel(previewResult: preview)
                showCSVPreview = true
            } catch {
                exportError = error.localizedDescription
            }

            isPreparingCSVPreview = false
        }
    }

    private var toastView: some View {
        Text(toastMessage.isEmpty ? String(localized: "settings.data.comingSoon") : toastMessage)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(DesignSystem.Colors.textPrimary.opacity(0.9))
            .clipShape(Capsule())
    }

    private var csvImportLoadingOverlay: some View {
        ZStack {
            DesignSystem.Colors.bgPage.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.block) {
                ProgressView()
                    .tint(DesignSystem.Colors.primary)

                Text(String(localized: "csv.import.preview.loading"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }
}
