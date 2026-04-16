import SwiftData
import SwiftUI

struct EventListStateContainer: View {
    let state: LoadingState<[Event]>
    let filteredUpcomingEvents: [Event]
    let filteredPastEvents: [Event]
    let hasNoResults: Bool
    let selectedTypeFilter: EventType?
    let upcomingBadge: (Date) -> String
    let onRetry: () -> Void
    let onAddEvent: () -> Void
    let onSelectAllFilter: () -> Void
    let onSelectTypeFilter: (EventType) -> Void
    let onSelectEvent: (Event) -> Void
    let onDeleteEvent: (Event) -> Void

    var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .loaded(events) where events.isEmpty:
                EmptyStateView(
                    icon: "calendar",
                    message: String(localized: "event.list.empty"),
                    actionTitle: String(localized: "event.add.title"),
                    action: onAddEvent
                )
            case .loaded:
                EventListContentView(
                    filteredUpcomingEvents: filteredUpcomingEvents,
                    filteredPastEvents: filteredPastEvents,
                    hasNoResults: hasNoResults,
                    selectedTypeFilter: selectedTypeFilter,
                    upcomingBadge: upcomingBadge,
                    onSelectAllFilter: onSelectAllFilter,
                    onSelectTypeFilter: onSelectTypeFilter,
                    onSelectEvent: onSelectEvent,
                    onDeleteEvent: onDeleteEvent
                )
            case let .error(message):
                ErrorStateView(message: message, retryAction: onRetry)
            }
        }
    }
}

private struct EventListContentView: View {
    let filteredUpcomingEvents: [Event]
    let filteredPastEvents: [Event]
    let hasNoResults: Bool
    let selectedTypeFilter: EventType?
    let upcomingBadge: (Date) -> String
    let onSelectAllFilter: () -> Void
    let onSelectTypeFilter: (EventType) -> Void
    let onSelectEvent: (Event) -> Void
    let onDeleteEvent: (Event) -> Void

    var body: some View {
        List {
            EventListRowContainer(bottomInset: 12) {
                EventTypeFilterPills(
                    selectedTypeFilter: selectedTypeFilter,
                    onSelectAll: onSelectAllFilter,
                    onSelectType: onSelectTypeFilter
                )
            }

            if hasNoResults {
                EventListRowContainer {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        message: String(localized: "event.list.noResults")
                    )
                }
            } else {
                if !filteredUpcomingEvents.isEmpty {
                    EventListSection(
                        title: String(localized: "event.list.upcoming"),
                        events: filteredUpcomingEvents,
                        badgeText: upcomingBadge,
                        onSelectEvent: onSelectEvent,
                        onDeleteEvent: onDeleteEvent
                    )
                }

                if !filteredPastEvents.isEmpty {
                    EventListSection(
                        title: String(localized: "event.list.past"),
                        events: filteredPastEvents,
                        badgeText: { _ in nil },
                        onSelectEvent: onSelectEvent,
                        onDeleteEvent: onDeleteEvent
                    )
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

private struct EventTypeFilterPills: View {
    let selectedTypeFilter: EventType?
    let onSelectAll: () -> Void
    let onSelectType: (EventType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                EventTypeFilterChip(
                    title: String(localized: "record.filter.all"),
                    iconName: nil,
                    isSelected: selectedTypeFilter == nil,
                    action: onSelectAll
                )

                ForEach(EventType.allCases, id: \.self) { type in
                    EventTypeFilterChip(
                        title: type.displayName,
                        iconName: type.iconName,
                        isSelected: selectedTypeFilter == type,
                        action: { onSelectType(type) }
                    )
                }
            }
        }
        .padding(.top, 8)
    }
}

private struct EventTypeFilterChip: View {
    let title: String
    let iconName: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(DesignSystem.Typography.small)
                }

                Text(title)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textPrimary)
            .padding(.horizontal, iconName == nil ? 16 : 14)
            .padding(.vertical, 8)
            .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.bgCard)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct EventListSection: View {
    let title: String
    let events: [Event]
    let badgeText: (Date) -> String?
    let onSelectEvent: (Event) -> Void
    let onDeleteEvent: (Event) -> Void

    var body: some View {
        Section {
            ForEach(events) { event in
                EventListRow(
                    event: event,
                    badge: badgeText(event.date),
                    onTap: { onSelectEvent(event) },
                    onDelete: { onDeleteEvent(event) }
                )
            }
        } header: {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)
                .textCase(nil)
                .padding(.top, 10)
        }
    }
}

private struct EventListRow: View {
    let event: Event
    let badge: String?
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            EventRowCard(
                name: event.name,
                coverImage: event.coverImage,
                eventType: event.type,
                date: event.date,
                location: event.location,
                recordCount: (event.records ?? []).count,
                badge: badge
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("event.list.row.\(event.name)")
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label(String(localized: "common.delete"), systemImage: "trash")
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 10, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

private struct EventListRowContainer<Content: View>: View {
    let bottomInset: CGFloat
    @ViewBuilder let content: Content

    init(bottomInset: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.bottomInset = bottomInset
        self.content = content()
    }

    var body: some View {
        content
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: bottomInset, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
