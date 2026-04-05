import SwiftData
import SwiftUI

struct RecordRow: View {
    let record: Record

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(imageData: record.contact?.avatar, name: contactName)

            VStack(alignment: .leading, spacing: 3) {
                Text(contactName)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(record.contextDisplayName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(dateText)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            if record.recordType.isMonetary {
                Text(amountText)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(amountColor)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(record.recordType.iconEmoji)
                            .font(DesignSystem.Typography.caption)
                        Text(record.resolvedDescription)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(maxWidth: 140, alignment: .trailing)
                    if record.resolvedDisplayAmount > 0 {
                        Text(amountText)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private var contactName: String {
        record.contact?.name ?? ""
    }

    private var amountText: String {
        let prefix = record.direction == .received ? "+ " : "- "
        let value = record.resolvedDisplayAmount
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
        return prefix + "¥" + formatted
    }

    private var amountColor: Color {
        record.direction == .received
            ? DesignSystem.Colors.accentGold
            : DesignSystem.Colors.primary
    }

    private var dateText: String {
        DateFormatters.monthDayCurrentLocale.string(from: record.date)
    }
}

#Preview("Record row") {
    let schema = Schema([Contact.self, Event.self, Record.self, RecordPhoto.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let contact = Contact(name: "张三")
    let event = Event(name: "婚礼", type: .wedding, date: .now)
    context.insert(contact)
    context.insert(event)
    let record = Record.makeMonetaryRecord(contact: contact, event: event, amount: 800, direction: .received)
    context.insert(record)
    return RecordRow(record: record)
        .modelContainer(container)
}
