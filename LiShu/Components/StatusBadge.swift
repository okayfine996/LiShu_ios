import SwiftUI

struct StatusBadge: View {
    let badge: RecordReturnGiftBadge

    var body: some View {
        switch badge {
        case .omitted:
            EmptyView()
        case .received, .notReturned, .returned:
            Text(statusText)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(statusBackground)
                .clipShape(Capsule())
        }
    }

    private var statusText: String {
        switch badge {
        case .received:
            return String(localized: "record.status.received")
        case .notReturned:
            return String(localized: "record.returnGift.notReturned")
        case .returned:
            return String(localized: "record.returnGift.returned")
        case .omitted:
            return ""
        }
    }

    private var statusColor: Color {
        switch badge {
        case .received:
            return DesignSystem.Colors.accentGold
        case .notReturned:
            return DesignSystem.Colors.primary
        case .returned:
            return DesignSystem.Colors.accentGold
        case .omitted:
            return DesignSystem.Colors.textSecondary
        }
    }

    private var statusBackground: Color {
        switch badge {
        case .received:
            return DesignSystem.Colors.accentGold.opacity(0.12)
        case .notReturned:
            return DesignSystem.Colors.primary.opacity(0.12)
        case .returned:
            return DesignSystem.Colors.accentGold.opacity(0.12)
        case .omitted:
            return Color.clear
        }
    }
}

#Preview {
    HStack {
        StatusBadge(badge: .received)
        StatusBadge(badge: .notReturned)
        StatusBadge(badge: .returned)
    }
}
