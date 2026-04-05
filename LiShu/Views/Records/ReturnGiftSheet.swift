import SwiftUI
import SwiftData

struct ReturnGiftSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let recordID: PersistentIdentifier

    @State private var record: Record?
    @State private var returnAmountText: String = ""
    @State private var validationError: String?
    @State private var isShowingErrorAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if let record {
                    recordInfoCard(record)
                    returnAmountSection(record)
                    confirmButton(record)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "record.detail.returnGift"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(String(localized: "common.cancel")) {
                    dismiss()
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .accessibilityIdentifier("returnGift.cancelButton")
            }
        }
        .onAppear {
            record = modelContext.model(for: recordID) as? Record
        }
        .alert(String(localized: "record.returnGift.validationTitle"), isPresented: $isShowingErrorAlert) {
            Button(String(localized: "common.confirm"), role: .cancel) {}
        } message: {
            if let validationError {
                Text(validationError)
            }
        }
    }

    // MARK: - Record Info Card

    private func recordInfoCard(_ record: Record) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AvatarView(imageData: record.contact?.avatar, name: record.contact?.name ?? "")
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.contact?.name ?? "")
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(record.contextDisplayName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }

            Divider()
                .foregroundStyle(DesignSystem.Colors.separator)

            HStack(spacing: 8) {
                amountInfoRow(
                    label: String(localized: "record.detail.giftAmount"),
                    value: formatAmount(record.monetaryAmount),
                    highlighted: false
                )
                amountInfoRow(
                    label: String(localized: "record.detail.returnAmount"),
                    value: formatAmount(record.resolvedReturnedAmount),
                    highlighted: false
                )
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private func amountInfoRow(label: String, value: String, highlighted: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(highlighted ? .white.opacity(0.8) : DesignSystem.Colors.textSecondary)
            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(highlighted ? .white : DesignSystem.Colors.textPrimary)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(highlighted ? DesignSystem.Colors.primary : DesignSystem.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    // MARK: - Return Amount Section

    private func returnAmountSection(_ record: Record) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.detail.returnAmountLabel"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                Text("\u{00A5}")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                TextField(String(localized: "0"), text: $returnAmountText)
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("returnGift.amountField")
            }
            .padding(12)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Confirm Button

    private func confirmButton(_ record: Record) -> some View {
        Button {
            performReturn(record)
        } label: {
            Text(String(localized: "record.detail.confirmReturn"))
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!isValid(record))
        .opacity(isValid(record) ? 1.0 : 0.6)
        .accessibilityIdentifier("returnGift.confirmButton")
    }

    // MARK: - Validation & Save

    /// 尚可记入的退礼上限（礼金 − 已退），不对外展示
    private func maxAdditionalReturn(for record: Record) -> Double {
        max(0, record.monetaryAmount - record.resolvedReturnedAmount)
    }

    private func isValid(_ record: Record) -> Bool {
        guard let value = UserEnteredDecimal.parse(returnAmountText), value > 0 else { return false }
        return value <= maxAdditionalReturn(for: record)
    }

    private func performReturn(_ record: Record) {
        guard let returnValue = UserEnteredDecimal.parse(returnAmountText), returnValue > 0 else {
            validationError = String(localized: "record.returnGift.amountRequired")
            isShowingErrorAlert = true
            return
        }
        guard returnValue <= maxAdditionalReturn(for: record) else {
            validationError = String(localized: "record.returnGift.exceedsOutstanding")
            isShowingErrorAlert = true
            return
        }

        guard var monetary = record.monetaryData else {
            validationError = String(localized: "record.returnGift.monetaryDataMissing")
            isShowingErrorAlert = true
            return
        }
        monetary.returnedAmount += returnValue
        record.applyTypeData(.monetary(monetary))

        if record.hasReturnedGift {
            NotificationManager.shared.cancelReturnGiftReminder(record: record)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            validationError = error.localizedDescription
            isShowingErrorAlert = true
        }
    }

    // MARK: - Helpers

    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
        return "\u{00A5}" + formatted
    }
}

private struct ReturnGiftPreview: View {
    @Environment(\.modelContext) private var modelContext
    @State private var recordID: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            if let recordID {
                ReturnGiftSheet(recordID: recordID)
            } else {
                ProgressView()
            }
        }
        .onAppear { seedData() }
    }

    private func seedData() {
        let cal = Calendar.current
        let contact = Contact(name: "张三", relation: "朋友")
        let event = Event(name: "结婚大礼", type: .wedding, date: cal.date(byAdding: .day, value: -60, to: .now)!)
        modelContext.insert(contact)
        modelContext.insert(event)

        let record = Record(
            contact: contact,
            event: event,
            amount: 1000,
            direction: .given,
            paymentMethod: .wechat,
            returnedAmount: 200,
            date: cal.date(byAdding: .day, value: -60, to: .now)!
        )
        modelContext.insert(record)
        try? modelContext.save()
        recordID = record.persistentModelID
    }
}

#Preview {
    ReturnGiftPreview()
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
