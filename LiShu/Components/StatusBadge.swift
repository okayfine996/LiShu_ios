import SwiftUI

struct StatusBadge: View {
    let status: RecordStatus
    var direction: RecordDirection? = nil

    var body: some View {
        Text(statusText)
            .font(DesignSystem.Typography.small)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusBackground)
            .clipShape(Capsule())
    }

    private var isReceivedDirection: Bool {
        direction == .received
    }

    private var statusText: String {
        if isReceivedDirection {
            return String(localized: "record.status.received")
        }
        switch status {
        case .open: return String(localized: "record.status.open")
        case .partial: return String(localized: "record.status.partial")
        case .settled: return String(localized: "record.status.settled")
        }
    }

    private var statusColor: Color {
        if isReceivedDirection {
            return DesignSystem.Colors.accentGold
        }
        switch status {
        case .open: return DesignSystem.Colors.primary
        case .partial: return DesignSystem.Colors.accentGold
        case .settled: return DesignSystem.Colors.accentGold
        }
    }

    private var statusBackground: Color {
        if isReceivedDirection {
            return DesignSystem.Colors.accentGold.opacity(0.12)
        }
        switch status {
        case .open: return DesignSystem.Colors.primary.opacity(0.12)
        case .partial: return DesignSystem.Colors.accentGold.opacity(0.12)
        case .settled: return DesignSystem.Colors.accentGold.opacity(0.12)
        }
    }
}
