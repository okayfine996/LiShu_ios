import SwiftData
import SwiftUI

struct DeleteAllDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var confirmText = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

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
        }
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
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                deleteAllData()
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
            .disabled(!canDelete || isDeleting)
            .opacity(canDelete ? 1 : 0.5)

            Button {
                dismiss()
            } label: {
                Text(String(localized: "common.cancel"))
            }
            .buttonStyle(GhostButtonStyle())
        }
    }

    // MARK: - Delete action

    private func deleteAllData() {
        isDeleting = true
        errorMessage = nil
        do {
            try modelContext.delete(model: Record.self)
            try modelContext.delete(model: Event.self)
            try modelContext.delete(model: Contact.self)
            try modelContext.save()
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
