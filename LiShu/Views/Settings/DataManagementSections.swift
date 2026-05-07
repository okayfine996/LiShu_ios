import SwiftUI

struct DataManagementContentView: View {
    let onImportXLSX: () -> Void
    let isPreparingXLSXPreview: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                DataManagementImportSection(
                    onImportXLSX: onImportXLSX,
                    isPreparingXLSXPreview: isPreparingXLSXPreview
                )
                DataManagementExportSection()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

private struct DataManagementImportSection: View {
    let onImportXLSX: () -> Void
    let isPreparingXLSXPreview: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DataManagementSectionHeader(title: String(localized: "settings.data.section.import"))

            VStack(spacing: 0) {
                DataManagementActionRow(
                    icon: "doc.text",
                    title: String(localized: "settings.data.importExcel"),
                    action: onImportXLSX
                )

                DataManagementSectionDivider()

                DataManagementNavigationRow(
                    icon: "arrow.down.doc",
                    title: String(localized: "settings.data.downloadTemplate")
                ) {
                    ExcelTypeActionListView(mode: .templateDownload)
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))

            Text(String(localized: "settings.data.importHint"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .padding(.leading, 4)
        }
        .opacity(isPreparingXLSXPreview ? DesignSystem.Effects.disabledOpacity : 1)
    }
}

private struct DataManagementExportSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DataManagementSectionHeader(title: String(localized: "settings.data.section.export"))

            VStack(spacing: 0) {
                DataManagementNavigationRow(
                    icon: "square.and.arrow.up",
                    title: String(localized: "settings.data.exportExcel"),
                    isPro: true
                ) {
                    ExcelTypeActionListView(mode: .typedExport)
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))

            Text(String(localized: "settings.data.proHint"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .padding(.leading, 4)
        }
    }
}

private struct DataManagementSectionDivider: View {
    var body: some View {
        Divider()
            .background(DesignSystem.Colors.separator)
            .padding(.leading, 56)
    }
}

private struct DataManagementActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            DataManagementRowContent(icon: icon, title: title, isPro: false)
        }
        .buttonStyle(.plain)
    }
}

private struct DataManagementNavigationRow<Destination: View>: View {
    let icon: String
    let title: String
    let isPro: Bool
    @ViewBuilder let destination: Destination

    init(
        icon: String,
        title: String,
        isPro: Bool = false,
        @ViewBuilder destination: () -> Destination
    ) {
        self.icon = icon
        self.title = title
        self.isPro = isPro
        self.destination = destination()
    }

    var body: some View {
        NavigationLink(destination: destination) {
            DataManagementRowContent(icon: icon, title: title, isPro: isPro)
        }
        .buttonStyle(.plain)
    }
}

private struct DataManagementRowContent: View {
    let icon: String
    let title: String
    let isPro: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.body)
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
                .font(DesignSystem.Typography.small)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct DataManagementSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DesignSystem.Typography.small)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.leading, 4)
    }
}
