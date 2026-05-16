import Foundation

// MARK: - DeepLink

enum DeepLink: Equatable {
    case home
    case addRecord
    case addRecordForEvent(stableID: String)
    case giveGiftForEvent(stableID: String)
    case eventDetail(stableID: String)
    case contactDetail(stableID: String)

    static func from(_ url: URL) -> DeepLink? {
        guard url.scheme == "lishu" else { return nil }
        switch url.host {
        case "home": return .home
        case "add-record":
            let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let id = comps?.queryItems?.first(where: { $0.name == "event" })?.value {
                let direction = comps?.queryItems?.first(where: { $0.name == "direction" })?.value
                return direction == "given" ? .giveGiftForEvent(stableID: id) : .addRecordForEvent(stableID: id)
            }
            return .addRecord
        case "event":
            guard let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "id" })?.value
            else { return nil }
            return .eventDetail(stableID: id)
        case "contact":
            guard let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "id" })?.value
            else { return nil }
            return .contactDetail(stableID: id)
        default: return nil
        }
    }
}
