import Foundation

@MainActor
@Observable
final class NotificationRouter {
    static let shared = NotificationRouter()

    var pendingFestivalRoute: FestivalReminderRouteData?

    private init() {}

    func openFestivalDetail(_ route: FestivalReminderRouteData) {
        pendingFestivalRoute = route
    }

    func consumeFestivalRoute() -> FestivalReminderRouteData? {
        defer { pendingFestivalRoute = nil }
        return pendingFestivalRoute
    }
}
