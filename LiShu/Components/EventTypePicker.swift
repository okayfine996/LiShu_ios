import SwiftUI

struct EventTypePicker: View {
    @Binding var selected: EventType

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EventType.allCases, id: \.self) { eventType in
                    Button {
                        selected = eventType
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: eventType.iconName)
                                .font(.system(size: 14))
                            Text(eventType.displayName)
                                .font(DesignSystem.Typography.caption)
                        }
                        .foregroundStyle(
                            selected == eventType ? .white : DesignSystem.Colors.textPrimary
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selected == eventType ? DesignSystem.Colors.primary : DesignSystem.Colors.bgCard
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                selected == eventType ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                                lineWidth: 1
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - EventType Display

extension EventType {
    var iconName: String {
        switch self {
        case .wedding: return "heart.fill"
        case .engagement: return "heart.circle.fill"
        case .funeral: return "leaf.fill"
        case .birth: return "figure.and.child.holdinghands"
        case .birthday: return "gift.fill"
        case .longevity: return "birthday.cake.fill"
        case .festival: return "sparkles"
        case .property: return "house.fill"
        case .education: return "graduationcap.fill"
        case .business: return "storefront.fill"
        case .promotion: return "star.fill"
        case .visit: return "cross.case.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var displayName: String {
        switch self {
        case .wedding: return String(localized: "event.type.wedding")
        case .engagement: return String(localized: "event.type.engagement")
        case .funeral: return String(localized: "event.type.funeral")
        case .birth: return String(localized: "event.type.birth")
        case .birthday: return String(localized: "event.type.birthday")
        case .longevity: return String(localized: "event.type.longevity")
        case .festival: return String(localized: "event.type.festival")
        case .property: return String(localized: "event.type.property")
        case .education: return String(localized: "event.type.education")
        case .business: return String(localized: "event.type.business")
        case .promotion: return String(localized: "event.type.promotion")
        case .visit: return String(localized: "event.type.visit")
        case .other: return String(localized: "event.type.other")
        }
    }
}
