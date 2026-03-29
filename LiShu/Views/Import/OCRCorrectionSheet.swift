import SwiftUI

struct OCRCorrectionSheet: View {
    @Bindable var viewModel: OCRImportViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                nameField
                amountField
                eventField
                dateField
                Spacer()
                confirmButton
            }
            .padding(20)
            .background(DesignSystem.Colors.bgPage)
            .navigationTitle(String(localized: "ocr.correction.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Name Field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "ocr.correction.name"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            TextField(
                String(localized: "ocr.correction.namePlaceholder"),
                text: $viewModel.editName
            )
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.Colors.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Amount Field

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "ocr.correction.amount"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: 8) {
                Text("¥")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                TextField("0", text: $viewModel.editAmountText)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )

        }
    }

    // MARK: - Event Field

    private var eventField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "ocr.correction.event"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Menu {
                ForEach(EventType.allCases, id: \.self) { eventType in
                    Button {
                        viewModel.editEventName = eventType.displayName
                    } label: {
                        HStack {
                            Image(systemName: eventType.iconName)
                            Text(eventType.displayName)
                            if viewModel.editEventName == eventType.displayName {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.editEventName)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Date Field

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "ocr.correction.date"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack {
                DatePicker(
                    "",
                    selection: $viewModel.editDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(DesignSystem.Colors.primary)

                Spacer()

                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            viewModel.saveEditing()
            dismiss()
        } label: {
            Text(String(localized: "ocr.correction.confirm"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.editAmountParsed <= 0)
    }
}

#Preview {
    OCRCorrectionSheet(viewModel: {
        let vm = OCRImportViewModel()
        let item = OCRRecordItem(name: "张三", amount: 200, amountText: "200", confidence: .high)
        vm.startEditing(item: item)
        vm.items = [item]
        return vm
    }())
}
