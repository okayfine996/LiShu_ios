import SwiftData
import SwiftUI

struct OCRCorrectionSheet: View {
    @Bindable var viewModel: OCRImportViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                nameField
                amountField
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
    Group {
        if let container = makeOCRCorrectionPreviewContainer() {
            let eventID = ocrCorrectionPreviewEventID(from: container)
            OCRCorrectionSheet(viewModel: {
                let vm = OCRImportViewModel(eventID: eventID)
                let item = OCRRecordItem(name: "张三", amount: 200, amountText: "200", confidence: .high)
                vm.startEditing(item: item)
                vm.items = [item]
                return vm
            }())
                .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}

@MainActor
private func makeOCRCorrectionPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let event = Event(name: "我的婚礼礼簿", type: .wedding, hostMode: .host, date: .now)
    container.mainContext.insert(event)
    return container
}

@MainActor
private func ocrCorrectionPreviewEventID(from container: ModelContainer) -> PersistentIdentifier {
    let descriptor = FetchDescriptor<Event>()
    if let event = try? container.mainContext.fetch(descriptor).first {
        return event.persistentModelID
    }
    let fallbackEvent = Event(name: "我的婚礼礼簿", type: .wedding, hostMode: .host, date: .now)
    container.mainContext.insert(fallbackEvent)
    return fallbackEvent.persistentModelID
}
