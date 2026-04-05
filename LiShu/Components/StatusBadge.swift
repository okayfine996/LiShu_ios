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
            String(localized: "record.status.received")
        case .notReturned:
            String(localized: "record.returnGift.notReturned")
        case .returned:
            String(localized: "record.returnGift.returned")
        case .omitted:
            ""
        }
    }

    private var statusColor: Color {
        switch badge {
        case .received:
            DesignSystem.Colors.accentGold
        case .notReturned:
            DesignSystem.Colors.primary
        case .returned:
            DesignSystem.Colors.accentGold
        case .omitted:
            DesignSystem.Colors.textSecondary
        }
    }

    private var statusBackground: Color {
        switch badge {
        case .received:
            DesignSystem.Colors.accentGold.opacity(0.12)
        case .notReturned:
            DesignSystem.Colors.primary.opacity(0.12)
        case .returned:
            DesignSystem.Colors.accentGold.opacity(0.12)
        case .omitted:
            Color.clear
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
