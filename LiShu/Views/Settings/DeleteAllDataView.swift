import SwiftData
import SwiftUI

struct DeleteAllDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var confirmText = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var showDeleteConfirm = false

    private let requiredText = String(localized: "settings.delete.requiredText")

    private var canDelete: Bool {
        confirmText == requiredText
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                warningHeader
                dataList
                confirmInput
                Spacer()
                actionButtons
            }
            .padding(20)
            .background(DesignSystem.Colors.bgPage)
            .navigationTitle(String(localized: "settings.deleteAll"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .alert(String(localized: "common.error"), isPresented: $showErrorAlert) {
                Button(String(localized: "common.ok"), role: .cancel) {
                    showErrorAlert = false
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
            .alert(String(localized: "settings.delete.secondConfirmTitle"), isPresented: $showDeleteConfirm) {
                Button(String(localized: "common.cancel"), role: .cancel) {}
                    .accessibilityIdentifier("settings.deleteAllData.secondConfirmCancel")
                Button(String(localized: "common.delete"), role: .destructive) {
                    deleteAllData()
                }
                .accessibilityIdentifier("settings.deleteAllData.secondConfirmDelete")
            } message: {
                Text(settingsDeleteSummaryMessage)
            }
        }
    }

    private var settingsDeleteSummaryMessage: String {
        let contactCount = (try? modelContext.fetchCount(FetchDescriptor<Contact>())) ?? 0
        let eventCount = (try? modelContext.fetchCount(FetchDescriptor<Event>())) ?? 0
        let recordCount = (try? modelContext.fetchCount(FetchDescriptor<Record>())) ?? 0
        let photoCount = (try? modelContext.fetchCount(FetchDescriptor<RecordPhoto>())) ?? 0

        return String(
            format: String(localized: "settings.delete.confirmMessage %lld %lld %lld %lld"),
            Int64(contactCount),
            Int64(eventCount),
            Int64(recordCount),
            Int64(photoCount)
        )
    }

    // MARK: - Warning header

    private var warningHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(DesignSystem.Typography.display)
                .foregroundStyle(DesignSystem.Colors.destructive)

            Text(String(localized: "settings.delete.warning"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "settings.delete.irreversible"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Data list

    private var dataList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "settings.delete.willRemove"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                deleteItem(String(localized: "settings.delete.item.records"))
                deleteItem(String(localized: "settings.delete.item.contacts"))
                deleteItem(String(localized: "settings.delete.item.stats"))
            }
            .padding(16)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        }
    }

    private func deleteItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "minus.circle.fill")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.destructive)
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }

    // MARK: - Confirm input

    private var confirmInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: String(localized: "settings.delete.confirmHint"), requiredText))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            TextField(requiredText, text: $confirmText)
                .textFieldStyle(StandardTextFieldStyle())
                .accessibilityIdentifier("settings.deleteAllData.confirmTextField")
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showDeleteConfirm = true
            } label: {
                HStack {
                    if isDeleting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(String(localized: "settings.delete.action"))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("settings.deleteAllData.confirmButton")
            .disabled(!canDelete || isDeleting)
            .opacity(canDelete ? 1 : 0.5)

            Button {
                dismiss()
            } label: {
                Text(String(localized: "common.cancel"))
            }
            .buttonStyle(GhostButtonStyle())
            .accessibilityIdentifier("settings.deleteAllData.closeButton")
        }
    }

    // MARK: - Delete action

    private func deleteAllData() {
        guard canDelete else { return }

        isDeleting = true
        errorMessage = nil
        do {
            try modelContext.delete(model: Record.self)
            try modelContext.delete(model: Event.self)
            try modelContext.delete(model: Contact.self)
            try modelContext.save()
            showDeleteConfirm = false
            dismiss()
        } catch {
            isDeleting = false
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

#Preview {
    DeleteAllDataView()
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
