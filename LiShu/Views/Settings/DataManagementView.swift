import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showComingSoonToast = false
    @State private var toastMessage = ""
    @State private var showOCRImport = false
    @State private var showProSheet = false
    @State private var shareURL: URL?
    @State private var exportError: String?
    @State private var showCSVImporter = false
    @State private var importResult: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                importSection
                exportSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "settings.importExport"))
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if showComingSoonToast {
                toastView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 32)
            }
        }
        .fullScreenCover(isPresented: $showOCRImport) {
            OCRImportView()
        }
        .sheet(isPresented: $showProSheet) {
            NavigationStack {
                ProMembershipView()
            }
        }
        .sheet(item: Binding(
            get: { shareURL.map { ShareableFile(id: $0.absoluteString, url: $0) } },
            set: {
                if let url = shareURL, $0 == nil {
                    try? FileManager.default.removeItem(at: url)
                }
                shareURL = $0?.url
            }
        )) { item in
            ShareSheet(url: item.url) {
                shareURL = nil
                try? FileManager.default.removeItem(at: item.url)
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
        .fileImporter(
            isPresented: $showCSVImporter,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleCSVImport(result)
        }
    }

    // MARK: - Import Section

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "settings.data.section.import"))

            VStack(spacing: 0) {
                dataRow(
                    icon: "doc.viewfinder",
                    title: String(localized: "settings.data.importOCR"),
                    action: { showOCRImport = true }
                )

                Divider()
                    .background(DesignSystem.Colors.separator)
                    .padding(.leading, 56)

                dataRow(
                    icon: "doc.text",
                    title: String(localized: "settings.data.importCSV"),
                    action: { showCSVImporter = true }
                )
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))

            Text(String(localized: "settings.data.importHint"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .padding(.leading, 4)
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "settings.data.section.export"))

            VStack(spacing: 0) {
                dataRow(
                    icon: "doc.richtext.fill",
                    title: String(localized: "settings.data.exportCSV"),
                    isPro: true,
                    action: { performExportCSV() }
                )
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))

            Text(String(localized: "settings.data.proHint"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .padding(.leading, 4)
        }
    }

    // MARK: - Helpers

    private func dataRow(icon: String, title: String, isPro: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if isPro {
                    Text("Pro")
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.accentGold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.accentGold.opacity(0.15))
                        .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.small)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.leading, 4)
    }

    private func performExportCSV() {
        guard subscriptionManager.isPro else {
            showProSheet = true
            return
        }

        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "lishu_export_\(dateSuffix()).csv"
            guard let data = try ExportService.exportCSV(context: modelContext).data(using: .utf8) else {
                exportError = String(localized: "settings.data.export_encoding_failed")
                return
            }
            let fileURL = tempDir.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            shareURL = fileURL
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func dateSuffix() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f.string(from: Date())
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

    private func handleCSVImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            do {
                let res = try ExportService.importCSV(url: url, context: modelContext)
                importResult = String(
                    format: String(localized: "settings.data.importResult %lld %lld %lld"),
                    Int64(res.imported),
                    Int64(res.skipped),
                    Int64(res.errors)
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
            } catch {
                exportError = error.localizedDescription
            }
        case let .failure(error):
            exportError = error.localizedDescription
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
}

// MARK: - Shareable File

private struct ShareableFile: Identifiable {
    let id: String
    let url: URL
}

#Preview {
    NavigationStack {
        DataManagementView()
            .environment(SubscriptionManager.shared)
    }
    .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
