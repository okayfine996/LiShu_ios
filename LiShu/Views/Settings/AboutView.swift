import SwiftUI

struct AboutView: View {
    @State private var showDiagnosticsConsole = false
    @State private var diagnosticsTapCount = 0
    @State private var diagnosticsTapResetTask: DispatchWorkItem?

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var appBuildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var versionDisplayLine: String {
        let format = String(localized: "settings.about.versionWithBuild")
        return String(format: format, locale: Locale.current, arguments: [appVersion, appBuildNumber])
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
        .sheet(isPresented: $showDiagnosticsConsole) {
            NavigationStack {
                DiagnosticsConsoleContainerView()
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

            Text(versionDisplayLine)
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

    private func handleDiagnosticsTap() {
        guard PulseDiagnostics.isHiddenConsoleAvailable else { return }

        diagnosticsTapCount += 1
        diagnosticsTapResetTask?.cancel()

        if diagnosticsTapCount >= 7 {
            diagnosticsTapCount = 0
            requestDiagnosticsConsolePresentation()
            return
        }

        let resetTask = DispatchWorkItem {
            diagnosticsTapCount = 0
        }
        diagnosticsTapResetTask = resetTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: resetTask)
    }

    private func requestDiagnosticsConsolePresentation() {
        // Future validation layers can be inserted here before the console is shown.
        showDiagnosticsConsole = true
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
        let version = "\(appVersion) (\(appBuildNumber))"
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
