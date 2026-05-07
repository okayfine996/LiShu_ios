import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showComingSoonToast = false
    @State private var toastMessage = ""
    @State private var showXLSXPreview = false
    @State private var xlsxPreviewViewModel: ImportPreviewViewModel?
    @State private var exportError: String?
    @State private var showXLSXImporter = false
    @State private var importResult: String?
    @State private var didLoadUITestXLSXPreview = false
    @State private var didRequestUITestXLSXImporter = false
    @State private var isPreparingXLSXPreview = false

    var body: some View {
        DataManagementContentView(
            onImportXLSX: openXLSXImporter,
            isPreparingXLSXPreview: isPreparingXLSXPreview
        )
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "settings.importExport"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showXLSXPreview) {
            if let xlsxPreviewViewModel {
                ImportPreviewView(viewModel: xlsxPreviewViewModel) { result in
                    handleCompletedXLSXImport(result)
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
            if CommandLine.arguments.contains("--uitesting"), didRequestUITestXLSXImporter {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityElement()
                    .accessibilityIdentifier("xlsx.importer.requested")
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
            if isPreparingXLSXPreview {
                xlsxImportLoadingOverlay
            }
        }
        .fileImporter(
            isPresented: $showXLSXImporter,
            allowedContentTypes: [.xlsx],
            allowsMultipleSelection: false
        ) { result in
            handleXLSXImport(result)
        }
        .onChange(of: showXLSXPreview) { _, newValue in
            if !newValue {
                xlsxPreviewViewModel = nil
            }
        }
        .onAppear {
            loadUITestXLSXPreviewIfNeeded()
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

    private func openXLSXImporter() {
        guard !isPreparingXLSXPreview else { return }
        if CommandLine.arguments.contains("--uitesting") {
            didRequestUITestXLSXImporter = true
            if ProcessInfo.processInfo.environment["UITEST_SKIP_SYSTEM_XLSX_IMPORTER"] == "1" {
                return
            }
        }
        showXLSXImporter = true
    }

    private func handleXLSXImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            guard !isPreparingXLSXPreview else { return }
            isPreparingXLSXPreview = true

            Task {
                do {
                    let preview = try await ExportService.previewXLSXAsync(url: url)
                    xlsxPreviewViewModel = ImportPreviewViewModel(previewResult: preview)
                    showXLSXPreview = true
                } catch {
                    exportError = error.localizedDescription
                }

                isPreparingXLSXPreview = false
            }
        case let .failure(error):
            exportError = error.localizedDescription
        }
    }

    private func handleCompletedXLSXImport(_ result: ImportResult) {
        showXLSXPreview = false
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

    private func loadUITestXLSXPreviewIfNeeded() {
        guard !didLoadUITestXLSXPreview else { return }
        didLoadUITestXLSXPreview = true

        guard CommandLine.arguments.contains("--uitesting") else { return }
        guard let filePath = ProcessInfo.processInfo.environment["UITEST_XLSX_PREVIEW_PATH"], !filePath.isEmpty else { return }

        isPreparingXLSXPreview = true

        Task {
            do {
                let url = URL(fileURLWithPath: filePath)
                let preview = try await ExportService.previewXLSXAsync(url: url)
                xlsxPreviewViewModel = ImportPreviewViewModel(previewResult: preview)
                showXLSXPreview = true
            } catch {
                exportError = error.localizedDescription
            }

            isPreparingXLSXPreview = false
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

    private var xlsxImportLoadingOverlay: some View {
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
