import PulseUI
import SwiftUI

private struct DiagnosticsShareableFile: Identifiable {
    let id: String
    let url: URL
}

struct DiagnosticsConsoleContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exportedDiagnosticsFileURL: URL?
    @State private var diagnosticsExportErrorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ConsoleView()
                .closeButtonHidden()
                .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: Binding(
            get: { exportedDiagnosticsFileURL.map { DiagnosticsShareableFile(id: $0.absoluteString, url: $0) } },
            set: {
                if let url = exportedDiagnosticsFileURL, $0 == nil {
                    try? FileManager.default.removeItem(at: url)
                }
                exportedDiagnosticsFileURL = $0?.url
            }
        )) { item in
            ShareSheet(url: item.url) {
                exportedDiagnosticsFileURL = nil
                try? FileManager.default.removeItem(at: item.url)
            }
        }
        .alert("导出失败", isPresented: Binding(
            get: { diagnosticsExportErrorMessage != nil },
            set: { if !$0 { diagnosticsExportErrorMessage = nil } }
        )) {
            Button(String(localized: "common.ok")) {
                diagnosticsExportErrorMessage = nil
            }
        } message: {
            if let diagnosticsExportErrorMessage {
                Text(diagnosticsExportErrorMessage)
            }
        }
    }

    private var header: some View {
        ZStack {
            Text("Console")
                .font(.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Colors.bgSurface)
                        .clipShape(Capsule())
                }

                Spacer()

                Menu {
                    Button("导出详细文本日志") {
                        exportDiagnosticsLog(as: .detailedText)
                    }
                    Button("导出详细 JSON 日志") {
                        exportDiagnosticsLog(as: .jsonLines)
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(width: 36, height: 36)
                        .background(DesignSystem.Colors.bgSurface)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.bgPage)
    }

    private func exportDiagnosticsLog(as format: DiagnosticsExportService.ExportFormat) {
        do {
            switch format {
            case .detailedText:
                exportedDiagnosticsFileURL = try DiagnosticsExportService.exportDetailedLogs()
            case .jsonLines:
                exportedDiagnosticsFileURL = try DiagnosticsExportService.exportDetailedJSONLines()
            }
        } catch {
            diagnosticsExportErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        DiagnosticsConsoleContainerView()
    }
}
