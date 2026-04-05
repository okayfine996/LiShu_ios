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
        case .wedding: "heart.fill"
        case .engagement: "heart.circle.fill"
        case .funeral: "leaf.fill"
        case .birth: "figure.and.child.holdinghands"
        case .birthday: "gift.fill"
        case .longevity: "birthday.cake.fill"
        case .festival: "sparkles"
        case .property: "house.fill"
        case .education: "graduationcap.fill"
        case .business: "storefront.fill"
        case .promotion: "star.fill"
        case .visit: "cross.case.fill"
        case .other: "square.grid.2x2.fill"
        }
    }

    var displayName: String {
        switch self {
        case .wedding: String(localized: "event.type.wedding")
        case .engagement: String(localized: "event.type.engagement")
        case .funeral: String(localized: "event.type.funeral")
        case .birth: String(localized: "event.type.birth")
        case .birthday: String(localized: "event.type.birthday")
        case .longevity: String(localized: "event.type.longevity")
        case .festival: String(localized: "event.type.festival")
        case .property: String(localized: "event.type.property")
        case .education: String(localized: "event.type.education")
        case .business: String(localized: "event.type.business")
        case .promotion: String(localized: "event.type.promotion")
        case .visit: String(localized: "event.type.visit")
        case .other: String(localized: "event.type.other")
        }
    }
}
