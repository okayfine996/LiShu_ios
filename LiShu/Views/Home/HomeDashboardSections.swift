import SwiftData
import SwiftUI

struct HomeDashboardContentView: View {
    let snapshot: HomeDashboardSnapshot
    @Binding var sheetRoute: SheetRoute?

    var body: some View {
        VStack(spacing: 20) {
            HomeSummarySection(snapshot: snapshot)
            HomeLedgerSection(snapshot: snapshot, sheetRoute: $sheetRoute)
            HomeUpcomingSection(snapshot: snapshot)
            HomeRecentRecordsSection(snapshot: snapshot, sheetRoute: $sheetRoute)
        }
    }
}

private struct HomeSummarySection: View {
    let snapshot: HomeDashboardSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Text(String(localized: "home.yearSummaryTitle"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(HomeDashboardFormatters.lunarYearLabel)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    HomeFinancialSummaryCard(snapshot: snapshot)
                        .frame(width: HomeDashboardMetrics.summaryCardWidth, alignment: .top)

                    HomeRelationshipSummaryCard(snapshot: snapshot)
                        .frame(width: HomeDashboardMetrics.summaryCardWidth, alignment: .top)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .frame(height: 320)
        }
    }
}

private struct HomeLedgerSection: View {
    let snapshot: HomeDashboardSnapshot
    @Binding var sheetRoute: SheetRoute?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(localized: "event.ledger.sectionTitle"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Button(String(localized: "common.new")) {
                    sheetRoute = .addEvent
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.primary)
            }

            if snapshot.hostLedgerEvents.isEmpty {
                EmptyStateView(
                    icon: "book.closed",
                    message: String(localized: "event.ledger.homeEmpty"),
                    actionTitle: String(localized: "event.ledger.createHostEvent")
                ) {
                    sheetRoute = .addEvent
                }
                .frame(height: 220)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(snapshot.hostLedgerEvents) { event in
                            HomeLedgerCard(event: event) {
                                sheetRoute = .addLedgerReceipt(eventID: event.persistentModelID)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }
}

private struct HomeUpcomingSection: View {
    let snapshot: HomeDashboardSnapshot

    var body: some View {
        VStack(spacing: 12) {
            HomeSectionHeader(
                title: String(localized: "home.upcoming"),
                route: .eventList
            )

            if snapshot.upcomingEvents.isEmpty {
                HomeEmptyUpcomingCard()
            } else {
                CarouselView(
                    pageCount: snapshot.upcomingEvents.count,
                    autoScrollInterval: 3
                ) { index in
                    Group {
                        if let event = snapshot.upcomingEvents.element(at: index) {
                            VStack {
                                NavigationLink(value: AppRoute.eventDetail(event.persistentModelID)) {
                                    HomeUpcomingEventCard(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        } else {
                            Color.clear
                        }
                    }
                }
                .frame(height: 196)
            }
        }
    }
}

private struct HomeRecentRecordsSection: View {
    let snapshot: HomeDashboardSnapshot
    @Binding var sheetRoute: SheetRoute?

    var body: some View {
        VStack(spacing: 12) {
            HomeSectionHeader(title: String(localized: "home.recentRecords"))

            if snapshot.recentRecords.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "record.list.empty"),
                    actionTitle: String(localized: "home.addRecord")
                ) {
                    sheetRoute = .addRecord(direction: nil, contactID: nil, eventID: nil)
                }
                .accessibilityIdentifier("home.addRecordButton")
                .frame(height: 200)
            } else {
                VStack(spacing: 10) {
                    ForEach(snapshot.recentRecords) { record in
                        NavigationLink(value: AppRoute.recordDetail(record.persistentModelID)) {
                            HomeRecentRecordCard(record: record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
