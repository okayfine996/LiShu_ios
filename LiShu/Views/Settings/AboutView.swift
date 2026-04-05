import SwiftUI
import PulseUI

struct AboutView: View {
    @State private var showPulseConsole = false
    @State private var showDiagnosticsGuide = false
    /// Set with「打开诊断控制台」; cleared in `onDismiss` so the console sheet presents after the guide finishes dismissing.
    @State private var pendingPulseConsoleAfterGuideDismiss = false
    @State private var diagnosticsTapCount = 0
    @State private var diagnosticsTapResetTask: DispatchWorkItem?

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                appHeader
                linksSection
                legalSection
                copyrightFooter
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "settings.about"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDiagnosticsGuide, onDismiss: {
            if pendingPulseConsoleAfterGuideDismiss {
                pendingPulseConsoleAfterGuideDismiss = false
                showPulseConsole = true
            }
        }) {
            diagnosticsGuideSheet
        }
        .sheet(isPresented: $showPulseConsole) {
            NavigationStack {
                ConsoleView()
            }
        }
    }

    // MARK: - App header

    private var appHeader: some View {
        VStack(spacing: 12) {
            Text("\u{793C}")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 80, height: 80)
                .background(DesignSystem.Colors.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))

            Text(String(localized: "settings.about.appTagline"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(String(localized: "settings.about.version") + appVersion)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .accessibilityIdentifier("about.versionLabel")
                .onTapGesture {
                    handleDiagnosticsTap()
                }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var diagnosticsGuideSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("诊断控制台")
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("当需要排查问题时，可在此查看应用日志，并使用 Pulse 的原生分享功能导出日志文件。")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    diagnosticsStepCard(
                        title: "采集方式",
                        body: "日志会静默保存在本机沙盒中，并通过容量上限自动清理旧日志。"
                    )

                    diagnosticsStepCard(
                        title: "分享方式",
                        body: "进入控制台后，点击右上角分享按钮即可导出 .pulse 或文本日志，再通过系统分享发送给开发者。"
                    )

                    diagnosticsStepCard(
                        title: "覆盖范围",
                        body: PulseDiagnostics.supportSummary
                    )

                    Button {
                        pendingPulseConsoleAfterGuideDismiss = true
                        showDiagnosticsGuide = false
                    } label: {
                        Text("打开诊断控制台")
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DesignSystem.Colors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                    }
                    .accessibilityIdentifier("about.openDiagnosticsConsole")
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .background(DesignSystem.Colors.bgPage)
            .navigationTitle("诊断说明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        showDiagnosticsGuide = false
                    }
                }
            }
        }
    }

    private func diagnosticsStepCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.semibold)

            Text(body)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private func handleDiagnosticsTap() {
        guard PulseDiagnostics.isHiddenConsoleAvailable else { return }

        diagnosticsTapCount += 1
        diagnosticsTapResetTask?.cancel()

        if diagnosticsTapCount >= 7 {
            diagnosticsTapCount = 0
            showDiagnosticsGuide = true
            return
        }

        let resetTask = DispatchWorkItem {
            diagnosticsTapCount = 0
        }
        diagnosticsTapResetTask = resetTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: resetTask)
    }

    // MARK: - Links section

    private var linksSection: some View {
        VStack(spacing: 0) {
            aboutRow(icon: "bubble.left.fill", title: String(localized: "settings.about.feedback")) {
                openFeedbackMail()
            }
        }
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    // MARK: - Actions

    private func openFeedbackMail() {
        let subject = String(localized: "about.feedback.subject")
        let version = appVersion
        let systemVersion = UIDevice.current.systemVersion
        let device = UIDevice.current.model
        let body = "\n\n---\nApp: \(version)\niOS: \(systemVersion)\nDevice: \(device)"
        let urlString = "mailto:litesky@foxmail.com?subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Legal section

    private var legalSection: some View {
        VStack(spacing: 0) {
            NavigationLink(value: AppRoute.termsOfService) {
                aboutRowContent(icon: "doc.text.fill", title: String(localized: "settings.about.terms"))
            }
            .buttonStyle(.plain)

            Divider()
                .background(DesignSystem.Colors.separator)
                .padding(.leading, 52)

            NavigationLink(value: AppRoute.privacyPolicy) {
                aboutRowContent(icon: "shield.fill", title: String(localized: "settings.about.privacy"))
            }
            .buttonStyle(.plain)
        }
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    // MARK: - Copyright footer

    private var copyrightFooter: some View {
        Text(String(localized: "settings.about.copyright"))
            .font(DesignSystem.Typography.small)
            .foregroundStyle(DesignSystem.Colors.textTertiary)
    }

    // MARK: - Row helper

    private func aboutRowContent(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 28, height: 28)

            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func aboutRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            aboutRowContent(icon: icon, title: title)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
